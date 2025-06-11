
-- This generates an LFSR-based "body" that could be used
-- It is interruptable.  That is, if you issue go_pulse
-- while it's generating a header, it will abort that and start
-- a new header.


-- Example:
-- len_min1=3
-- osamp_min1=3
-- hdr_qty_min1=1
--
--  go_pulse        ____-______________-______-__
--  lfsr_state_ld   xxxx-xxxxxxxxxxxxxx-xxxxxx-xx
--  en              -----------------------------
--  ctr                  76543210       765432176543210
--  ctr_en          _____--------_______---------------___
--  ctr_atlim       ____________-_____________________-___

--  lfsr_state_in       a
--  lfsr_state           abcdefgh
--  lfsr_state_nxt_vld _________-____

--  lfsr_rst        ____-______________-______-__
--  lfsr_en         ____--------________
--  lfsr_data       _____ABCDEFGHHHHHHHH

--  dout_vld        ______--------_____
--  dout            ______ABCDEFGH_____
--

library ieee;
use ieee.std_logic_1164.all;
package gen_body_pkg is
  
  component gen_body
    generic (
      LEN_W: in integer;
      CP: in std_logic_vector;
      D_W: in integer);
    port (
      clk : in std_logic;
      rst : in std_logic;
      osamp_min1     : in std_logic_vector(1 downto 0); -- 0=1, 1=2, or 3=4
      
   -- units of cycles (typ at 308MHz).  Except zero means lots of cycles, not 1.
      len_min1 : in std_logic_vector(LEN_W-1 downto 0);

--    gen_en         : in  std_logic; -- TODO: MEANINGLESS
      lfsr_state_ld  : in  std_logic; -- sampled when go_pulse=1

      lfsr_state_in  : in  std_logic_vector(CP'length-1 downto 0);
      lfsr_state_nxt : out std_logic_vector(CP'length-1 downto 0);
      lfsr_state_nxt_vld : out std_logic;
      
      go_pulse    : in std_logic;
      -- if go_pulse held high will go uninteruptedly forever,
      -- regardless of len_min1. I think

      en: in std_logic;

      end_pre : out std_logic; -- high cyc before last valid cycle
      cyc_cnt_down : out std_logic_vector(LEN_W-1 downto 0);
      dout_vld     : out std_logic; -- high only during the headers
      dout         : out std_logic_vector(4*D_W-1 downto 0));
  end component;
  
end package;

library ieee;
use ieee.std_logic_1164.all;
entity gen_body is

  generic (
    LEN_W: in integer;
    CP: in std_logic_vector;
    D_W: in integer);
  port (
    clk : in std_logic;
    rst: in std_logic;

    osamp_min1    : in std_logic_vector(1 downto 0); -- 0=1, 1=2, or 3=4

--    gen_en         : in std_logic; -- if 0, lfsr_state_ld and go_pulse ignored
    lfsr_state_ld  : in std_logic;
    lfsr_state_in  : in std_logic_vector(CP'length-1 downto 0);
    lfsr_state_nxt : out std_logic_vector(CP'length-1 downto 0);
    lfsr_state_nxt_vld : out std_logic;
    
    go_pulse    : in std_logic;

    en: in std_logic;

    len_min1 : in std_logic_vector(LEN_W-1 downto 0); -- units of cycles at 308MHz

    end_pre      : out std_logic;
    cyc_cnt_down : out std_logic_vector(LEN_W-1 downto 0);
    dout_vld     : out std_logic; -- high only during the headers
    dout         : out std_logic_vector(4*D_W-1 downto 0));
end gen_body;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
use work.lfsr_w_pkg.all;
architecture rtl of gen_body is
  
  signal ctr: std_logic_vector(LEN_W-1 downto 0) := (others=>'0');

  signal tx, tx_pend, tx_pend_first, pd_ctr_atlim, lsfr_rst, lfsr_en,
    lfsr1_en, lfsr2_en, lfsr4_en,
    vld_i, ctr_atlim, lfsr_rst, ctr_en
    : std_logic:='0';

  signal lfsr1_data: std_logic_vector(4*D_W-1 downto 0);
  signal lfsr2_data: std_logic_vector(2*D_W-1 downto 0);
  signal lfsr4_data: std_logic_vector(1*D_W-1 downto 0);

  signal w1, w2, w4: std_logic_vector(4*D_W-1 downto 0);

  signal lfsr4_state_nxt, lfsr2_state_nxt, lfsr1_state_nxt:
    std_logic_vector(CP'length-1 downto 0);
  
begin

  lfsr_rst <= rst or (go_pulse and lfsr_state_ld);
  
  lfsr_en  <= go_pulse or ((ctr_en and not ctr_atlim) and en);

  lfsr4_en <= lfsr_en and u_b2b(osamp_min1="11");
  lfsr4: lfsr_w
    generic map(
      W => D_W,
      CP => CP)
    port map(
      d_o => lfsr4_data,
      en  => lfsr4_en,
      
      d_i => (others=>'0'),
      ld  => '0',

      rst_st => lfsr_state_in,
      rst    => lfsr_rst,
--    err    =>
      state_nxt => lfsr4_state_nxt,
      clk    => clk);
  w4 <= lfsr4_data & lfsr4_data & lfsr4_data & lfsr4_data;

  lfsr2_en <= lfsr_en and u_b2b(osamp_min1="01");
  lfsr2: lfsr_w
    generic map(
      W => 2*D_W,
      CP => CP)
    port map(
      d_o => lfsr2_data,
      en  => lfsr2_en,
      
      d_i => (others=>'0'),
      ld  => '0',

      rst_st => lfsr_state_in,
      rst    => lfsr_rst,
      state_nxt => lfsr2_state_nxt,
--    err    => 
      clk    => clk);
  w2 <= lfsr2_data & lfsr2_data;

  lfsr1_en <= lfsr_en and u_b2b(osamp_min1="00");
  lfsr1: lfsr_w
    generic map(
      W  => 4*D_W,
      CP => CP)
    port map(
      d_o => lfsr1_data,
      en  => lfsr1_en,
      
      d_i => (others=>'0'),
      ld  => '0',

      rst_st    => lfsr_state_in, 
      state_nxt => lfsr1_state_nxt,
      rst    => lfsr_rst,
--    err    => 
      clk    => clk);
  w1 <= lfsr1_data;  

  lfsr_state_nxt <= lfsr1_state_nxt when (osamp_min1="00")
               else lfsr2_state_nxt when (osamp_min1="01")
               else lfsr4_state_nxt;
  lfsr_state_nxt_vld <= ctr_atlim;
                                          

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

      vld_i <= ctr_en; -- ((gen_en and go_pulse) or hdr_vld_i) and not (rst or hdr_end);
      
      -- count the cycles in each hdr
      ctr_en <= not rst and (
                      go_pulse or (ctr_en and not (en and ctr_atlim)));
      if ((rst or go_pulse) ='1') then
        ctr       <= len_min1;
        ctr_atlim <= '0';
      elsif ((ctr_en and en)='1') then
        ctr       <= std_logic_vector(unsigned(ctr)-1);
        ctr_atlim <= u_b2b(unsigned(ctr)=1);
      end if;

    end if;
  end process;

  cyc_cnt_down  <= ctr;
  dout_vld  <= vld_i;
  end_pre <= ctr_en and en and ctr_atlim;
  
end rtl;
  
