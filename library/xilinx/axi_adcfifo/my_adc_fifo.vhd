library ieee;
use ieee.std_logic_1164.all;
entity my_adc_fifo is
  generic (
    D_W : integer);
  port (
   adc_rst : in std_logic;
    
   adc_clk : in std_logic;
   adc_wr  : in std_logic;
   adc_data: in std_logic_vector(D_W-1 downto 0);
   adc_wovf: out std_logic;
   clr_ovf : in std_logic;
   
   dma_clk   : in std_logic;
   dma_wready: in std_logic; -- from dmac s_axis_ready
   dma_wr    : out std_logic; -- to dmac s_axis_valid
   dma_data  : out std_logic_vector(D_W/2-1 downto 0));
  
end my_adc_fifo;

library work;
library ieee;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.util_pkg.all; 
architecture rtl of my_adc_fifo is
  
  component myfifo
  port (
    srst : in std_logic;
    wr_clk : in std_logic;
    rd_clk : in std_logic;
    din : in std_logic_vector(127 downto 0);
    wr_en : in std_logic;
    rd_en : in std_logic;
    dout : out std_logic_vector(127 downto 0);
    full : out std_logic;
    empty : out std_logic;
    wr_rst_busy : out std_logic;
    rd_rst_busy : out std_logic 
  );
 end component;

  signal fifo_wr, fifo_wr_req, fifo_wr_rst_busy, fifo_rd, fifo_rd_d, fifo_rd_rst_busy,
    fifo_full, fifo_mt, fifo_ovf, wr, mbox_rd, mbox_full, dma_rst
    : std_logic:='0';
  signal fifo_dout, mbox, shout, sav: std_logic_vector(127 downto 0);
  signal occ:   std_logic_vector(1 downto 0);
begin

  fifo_wr_req <= not adc_rst and not fifo_wr_rst_busy and adc_wr;
  fifo_wr <= fifo_wr_req and not fifo_full;
  f: myfifo
    port map(
      srst   => adc_rst,
      wr_clk => adc_clk,
      din    => adc_data,
      wr_en  => fifo_wr,
      full   => fifo_full,
      wr_rst_busy => fifo_wr_rst_busy,
      
      rd_clk => dma_clk,
      rd_en  => fifo_rd,
      dout   => fifo_dout,
      empty  => fifo_mt,
      rd_rst_busy => fifo_rd_rst_busy);

  process(adc_clk)
  begin
    if (rising_edge(adc_clk)) then
      if ((fifo_wr_req and fifo_full)='1') then
        fifo_ovf <= '1';
      elsif (clr_ovf='1') then
        fifo_ovf <= '1';
      end if;
    end if;
  end process;
  adc_wovf <= fifo_ovf;

  mbox <= fifo_dout when (fifo_rd_d='1') else sav;


  dma_rst <= fifo_rd_rst_busy;
  
  fifo_rd <= not mbox_full and not fifo_mt;
  mbox_rd <= mbox_full and (u_b2b(occ="00") or (u_b2b(occ="01") and wr));
  process(dma_clk)
  begin
    if (rising_edge(dma_clk)) then
      fifo_rd_d <= fifo_rd;
      
      if (fifo_rd_d='1') then
        sav <= fifo_dout;
      end if;
      mbox_full <= (fifo_rd or mbox_full) and not (dma_rst or mbox_rd);
      
      -- dma ctlr asserts dma_wready

      if (mbox_rd='1') then
        shout <= mbox;
      elsif (wr='1') then
        shout(63 downto 0) <= shout(127 downto 64);
      end if;

      if (dma_rst='1') then
        occ <= "00";
      elsif (mbox_rd='1') then
        occ <= "10";
      elsif (wr='1') then
        occ <= std_logic_vector(unsigned(occ)-1);
      end if;
    end if;
  end process;

  wr  <= u_or(occ) and dma_wready;
  dma_wr <= wr;

  dma_data <= shout(63 downto 0);
end rtl;
