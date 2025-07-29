
-- This generates an LFSR-based "header" that could be used
-- either for a CDM "probe" or a QSDC "pilot".
-- It is interruptable.  That is, if you issue go_pulse
-- while it's generating a header, it will abort that and start
-- a new header.


-- Example:
-- hdr_len_min1=3
-- osamp_min1=3
-- hdr_qty_min1=1
--
--  go_pulse        ____-______________-______-__
--  lfsr_state_ld   xxxx-xxxxxxxxxxxxxx-xxxxxx-xx
--  en              -----------------------------
--  hdr_ctr              76543210       765432176543210
--  hdr_ctr_en      _____--------_______---------------___
--  hdr_ctr_atlim   ____________-_____________________-___

--  lfsr_state_in       a
--  lfsr_state           abcdefgh
--  lfsr_state_nxt_vld _________-____

--  lfsr_rst        ____-______________-______-__
--  lfsr_en         ____--------________
--  lfsr_data       _____ABCDEFGHHHHHHHH
--  hdr_end_pre     ____________-_____
--  dout_vld        ______--------_____
--  dout            ______ABCDEFGH_____
--

library ieee;
use ieee.std_logic_1164.all;
package gen_hdr_pkg is
  
  component gen_hdr
    generic (
      HDR_LEN_W: in integer);
    port (
      clk : in std_logic;
      rst : in std_logic;
      osamp_min1     : in std_logic_vector(1 downto 0); -- 0=1, 1=2, or 3=4
      
      -- units of cycles (typ at 308MHz).  Except zero means lots of cycles, not 1.
      hdr_len_min1_cycs : in std_logic_vector(HDR_LEN_W-1 downto 0);

      gen_en         : in  std_logic; -- TODO: MEANINGLESS
      
      lfsr_state_ld  : in  std_logic; -- sampled when go_pulse=1
      lfsr_state_in  : in  std_logic_vector(10 downto 0);
      lfsr_state_nxt : out std_logic_vector(10 downto 0);
      lfsr_state_nxt_vld : out std_logic;
      
      go_pulse    : in std_logic;

      en: in std_logic;

      hdr_end_pre2 : out std_logic; -- high before before last valid cycle
      hdr_end_pre  : out std_logic; -- high before last valid cycle
      cyc_cnt_down : out std_logic_vector(HDR_LEN_W-1 downto 0);
      dout_vld     : out std_logic; -- high only during the headers
      dout         : out std_logic_vector(3 downto 0));
  end component;
  
end package;

library ieee;
use ieee.std_logic_1164.all;
entity gen_hdr is

  generic (
    HDR_LEN_W: integer);
  port (
    clk : in std_logic;
    rst: in std_logic;

    osamp_min1    : in std_logic_vector(1 downto 0); -- 0=1, 1=2, or 3=4

    gen_en         : in std_logic; -- if 0, lfsr_state_ld and go_pulse ignored
    lfsr_state_ld  : in std_logic;
    lfsr_state_in  : in std_logic_vector(10 downto 0);
    lfsr_state_nxt : out std_logic_vector(10 downto 0);
    lfsr_state_nxt_vld : out std_logic;
    
    go_pulse    : in std_logic;

    en: in std_logic;

    hdr_len_min1_cycs : in std_logic_vector(HDR_LEN_W-1 downto 0); -- units of cycles at 308MHz

    hdr_end_pre2 : out std_logic;
    hdr_end_pre  : out std_logic;
    cyc_cnt_down : out std_logic_vector(HDR_LEN_W-1 downto 0);
    dout_vld     : out std_logic; -- high only during the headers
    dout         : out std_logic_vector(3 downto 0));
end gen_hdr;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
use work.lfsr_w_pkg.all;
architecture rtl of gen_hdr is

  signal hdr_ctr: std_logic_vector(HDR_LEN_W-1 downto 0) := (others=>'0');

  signal tx, tx_pend, tx_pend_first, pd_ctr_atlim, lsfr_rst, lfsr_en,
    dout_vld_i, hdr_ctr_atlim_pre, hdr_ctr_atlim, lfsr_rst, hdr_ctr_en, end_pul_i
    : std_logic:='0';

  signal lfsr4_data: std_logic_vector(0 downto 0);
  signal lfsr2_data: std_logic_vector(1 downto 0);
  signal lfsr1_data: std_logic_vector(3 downto 0);

  signal w1, w2, w4: std_logic_vector(3 downto 0);

  signal lfsr_state_nxt4, lfsr_state_nxt2, lfsr_state_nxt1:
    std_logic_vector(10 downto 0);
  
begin

  lfsr_rst <= rst or (go_pulse and lfsr_state_ld);
  
  lfsr_en  <= go_pulse or ((hdr_ctr_en and not hdr_ctr_atlim) and en);

  lfsr4: lfsr_w
    generic map(
      W => 1,
      CP => "01000000001") -- x^11 + x^9 + 1
    port map(
      d_o => lfsr4_data,
      en  => lfsr_en,
      
      d_i => (others=>'0'),
      ld  => '0',

      rst_st => lfsr_state_in,
      rst    => lfsr_rst,
--    err    =>
      state_nxt => lfsr_state_nxt4,
      clk    => clk);
  w4 <= lfsr4_data & lfsr4_data & lfsr4_data & lfsr4_data;

  lfsr2: lfsr_w
    generic map(
      W => 2,
      CP => "01000000001") -- x^11 + x^9 + 1
    port map(
      d_o => lfsr2_data,
      en  => lfsr_en,
      
      d_i => (others=>'0'),
      ld  => '0',

      rst_st => lfsr_state_in,
      rst    => lfsr_rst,
      state_nxt => lfsr_state_nxt2,
--    err    => 
      clk    => clk);
  w2 <= lfsr2_data & lfsr2_data;

  lfsr1: lfsr_w
    generic map(
      W => 4,
      CP => "01000000001") -- x^11 + x^9 + 1
    port map(
      d_o => w1,
      en  => lfsr_en,
      
      d_i => (others=>'0'),
      ld  => '0',

      rst_st => lfsr_state_in, 
      state_nxt => lfsr_state_nxt1,
     rst    => lfsr_rst,
--    err    => 
      clk    => clk);
  

  lfsr_state_nxt <= lfsr_state_nxt1 when (osamp_min1="00")
               else lfsr_state_nxt2 when (osamp_min1="01")
               else lfsr_state_nxt4;
  lfsr_state_nxt_vld <= hdr_ctr_atlim;
                                          

--  pd_tic <= pd_ctr_atlim;
  clk_proc: process(clk) is
  begin
    if (rising_edge(clk)) then
      if (osamp_min1="00") then -- oversamp by 1
        dout <= w1;
      elsif (osamp_min1="01") then -- oversamp by 2
        dout <= w2;
      else -- oversample by 4
        dout <= w4; 
      end if;

      dout_vld_i <= hdr_ctr_en; -- ((gen_en and go_pulse) or dout_vld_i) and not (rst or hdr_end);
      
      -- count the cycles in each hdr
      hdr_ctr_en <= not rst and (
                      go_pulse or (hdr_ctr_en and not (en and hdr_ctr_atlim)));
      if ((rst or go_pulse) ='1') then
        hdr_ctr       <= hdr_len_min1_cycs;
        hdr_ctr_atlim <= '0';
      elsif ((hdr_ctr_en and en)='1') then
        hdr_ctr       <= std_logic_vector(unsigned(hdr_ctr)-1);
        hdr_ctr_atlim_pre <= u_b2b(unsigned(hdr_ctr)=2);
        hdr_ctr_atlim <= u_b2b(unsigned(hdr_ctr)=1);
      end if;

    end if;
  end process;

  cyc_cnt_down <= hdr_ctr;
  dout_vld      <= dout_vld_i;
  hdr_end_pre2  <= hdr_ctr_en and en and hdr_ctr_atlim_pre;
  hdr_end_pre  <= hdr_ctr_en and en and hdr_ctr_atlim;
  
end rtl;
  
