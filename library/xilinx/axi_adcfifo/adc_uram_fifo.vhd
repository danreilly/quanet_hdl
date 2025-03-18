
-- adc_uram_fifo
-- This is a special fifo for data comming from the ADC
-- going out via DMA.
-- Implemented using uram

library ieee;
use ieee.std_logic_1164.all;
entity adc_uram_fifo is
  generic (
    D_W: in integer := 128; -- mult of 64
    URAM_A_W: in integer := 12); -- must be mult of 12
  port (
    ctl_clk   : in std_logic;
    rst       : in std_logic; -- clears all internal content. does not clear flags
    fifo_ovf  : out std_logic;
    fifo_bug  : out std_logic; -- internal fifo ovf that supposedly never can
                               -- ovf.  If it does, adjust almost full thresh.
    clr_flags : in std_logic;

    adc_clk    : in std_logic; -- typically 312.5MHz
    adc_wr     : in  std_logic;
    adc_data   : in  std_logic_vector(D_W-1 downto 0);

    dma_clk    : in std_logic;  -- typically 250MHz
    dma_wready : in std_logic;  -- asserted by dmac
    dma_wr     : out std_logic; -- to dmac
    dma_data   : out std_logic_vector(D_W-1 downto 0)); -- to dmac
end adc_uram_fifo;

library unisim;
use unisim.vcomponents.all;
library ieee;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.util_pkg.all;
use work.cdc_samp_pkg.all;
use work.cdc_pulse_pkg.all;
use work.fifo_2clks_infer_pkg.all;
architecture struct of adc_uram_fifo is
  
  component fifo_1clk_uram_infer
    generic (
      C_AWIDTH : in integer := 12;
      C_DWIDTH : in integer := 72;
      C_NBPIPE : in integer := 3);
    port (
      clk: in std_logic;
      rst: in std_logic;

      -- Port A
      w    : in  std_logic;                              
      din  : in  std_logic_vector(C_DWIDTH-1 downto 0); 
      full : out std_logic;

      r    : in  std_logic;
      dout : out std_logic_vector(C_DWIDTH-1 downto 0);
      dout_vld : out std_logic;
      mt   : out std_logic);
  end component;

  
  constant WORDS: integer := D_W/64;
  constant UFIFO_D_W: integer := WORDS*72;
  signal ufifo_din, ufifo_dout: std_logic_vector(UFIFO_D_W-1 downto 0) := (others=>'0');
  signal ufifo_rst: std_logic;
  signal ufifo_full, ufifo_ovf_pulse,
    ufifo_dout_vld, ufifo_mt, ufifo_r, ufifo_w: std_logic := '0';
  signal rst_dly: std_logic_vector(1 downto 0);

  signal ccfifo_din: std_logic_vector(D_W-1 downto 0);
  signal ccfifo_ovf_pulse, fifo_ovf_pulse, fifo_bug_pulse, fifo_ovf_i, fifo_bug_i,
    ccfifo_rst, ccfifo_w, ccfifo_full, ccfifo_pf, ccfifo_vld, ccfifo_r, ccfifo_mt, dma_rdy, ccfifo_ovf: std_logic:='0';
  signal ccfifo_occ: std_logic_vector(4 downto 0);
begin

  cdc_ufifo_rst: cdc_samp
    generic map( W => 1)
    port map(
      in_data(0)  => rst,
      out_data(0) => ufifo_rst,
      out_clk     => adc_clk);

  
  gen_words: for k in 0 to WORDS-1 generate
    ufifo_din(k*72+63 downto k*72)  <= adc_data(k*64+63 downto k*64);
    ccfifo_din(k*64+63 downto k*64) <= ufifo_dout(k*72+63 downto k*72);
  end generate;

  -- URAM based fifo
  -- This can be rather deep but uses only one clock
  ufifo_w <= adc_wr and not ufifo_full;
  ufifo: fifo_1clk_uram_infer
    generic map(
      C_AWIDTH => URAM_A_W,
      C_DWIDTH => UFIFO_D_W)
    port map(
      clk => adc_clk,
      rst => ufifo_rst,

      w    => ufifo_w,
      din  => ufifo_din,
      full => ufifo_full, -- during rst is 0

      r        => ufifo_r,
      dout     => ufifo_dout,
      dout_vld => ufifo_dout_vld,
      mt       => ufifo_mt);

  -- Cross-Clock Fifo
  -- indep clks, distrib RAM, 2 sync stages
  -- first word fall thru, width 128, depth 16, async reset pin, en rst sync
  -- almost full, valid, full_type single prog thresh = 12
  -- more accurate data cnts
  --
  -- The wizard did not allow a prog thresh lower than 12.
  -- But I needed one because of the many-cycle latency of the uram fifo.
  -- So I switched to using the occupancy count.
  -- 
  -- uram fifo is drained into this fifo as fast as possible.
  --
  ccfifo_w <= ufifo_dout_vld and not ccfifo_full;
  ccfifo: fifo_2clks_infer
    generic map(
      A_W  => 4, -- max occ is 2**A_W-1
      D_W  => D_W, -- width of fifo
      AFULL_OCC => 9, -- occupancy when almost full.
      HAS_FIRST_WORD_FALLTHRU => true)
    port map(
      wclk  => adc_clk,
      rst   => rst, -- any clk domain
      din   => ccfifo_din,
      wr_en => ccfifo_w,
      full  => ccfifo_full, -- 0 during rst
      afull => ccfifo_pf, 
      
--      w_mt: out std_logic; -- write-side mt flag, 1 during rst.
      -- pessimisively indicates not mt,
      -- but when indicates mt, fifo is truely mt.

      rclk      => dma_clk,
      rd_en     => ccfifo_r,
--      rd_occ: out std_logic_vector(A_W-1 downto 0);
      dout    => dma_data,
      mt      => ccfifo_mt);


  
  ccfifo_r <= not ccfifo_mt and dma_wready;
  dma_wr <= ccfifo_r;

--  ccfifo_pf <= u_b2b(unsigned(ccfifo_occ)>10);
  process(adc_clk)
  begin
    if (rising_edge(adc_clk)) then
      ufifo_ovf_pulse  <= not ufifo_rst and (adc_wr and ufifo_full); -- will happen
      ccfifo_ovf_pulse <= not ufifo_rst and (ufifo_dout_vld and ccfifo_full); -- should never happen
      ufifo_r          <= not ufifo_rst and not ufifo_mt and not ccfifo_pf;
    end if;
  end process;

  ovf_pulse_bridge: cdc_pulse
    port map (
      in_pulse  => ufifo_ovf_pulse,
      in_clk    => adc_clk,
      out_pulse => fifo_ovf_pulse,
      out_clk   => ctl_clk);
  bug_pulse_bridge: cdc_pulse
    port map (
      in_pulse  => ccfifo_ovf_pulse,
      in_clk    => adc_clk,
      out_pulse => fifo_bug_pulse,
      out_clk   => ctl_clk);
  process(ctl_clk)
  begin
    if (rising_edge(ctl_clk)) then
      fifo_ovf_i <= not clr_flags and (fifo_ovf_pulse or fifo_ovf_i);
      fifo_bug_i <= not clr_flags and (fifo_bug_pulse or fifo_bug_i);
    end if;
  end process;
  fifo_ovf <= fifo_ovf_i;
  fifo_bug <= fifo_bug_i;
  
end architecture struct;
