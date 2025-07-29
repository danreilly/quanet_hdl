-- gen_cipher
--
-- This generates a stream of M-psk symbols
-- based on an LFSR.  The security can eventually
-- be augmented with a TRNG and other means.

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
package gen_cipher_pkg is
  
  component gen_cipher
    generic (
      LEN_W: in integer;
      CP: in std_logic_vector;
      M_MAX: in integer;
      LOG2M_MAX: in integer; -- 4
      LOG2M_W: in integer;   -- 3
      DAC_W: in integer); -- 16
    port (
      clk : in std_logic;
      rst : in std_logic;
      osamp_min1     : in std_logic_vector(1 downto 0); -- 0=1, 1=2, or 3=4

      -- when this component generates M-PSK, M is determined by:
      log2m : in std_logic_vector(LOG2M_W-1 downto 0); -- log2 of M. 1...LOG2M_MAX
      
      -- units of cycles (typ at 308MHz).  Except zero means lots of cycles, not 1.
      len_min1 : in std_logic_vector(LEN_W-1 downto 0);

      lfsr_state_ld  : in  std_logic; -- sampled when go_pulse=1

      lfsr_state_in  : in  std_logic_vector(CP'length-1 downto 0);
      lfsr_state_nxt : out std_logic_vector(CP'length-1 downto 0);
--      lfsr_state_nxt_vld : out std_logic;
      
      go_pulse    : in std_logic;
      -- if go_pulse held high will go uninteruptedly forever,
      -- regardless of len_min1. I think

      en: in std_logic;

--      end_pre : out std_logic; -- high cyc before last valid cycle

      dout_vld     : out std_logic; -- high only during the headers
      dout         : out std_logic_vector(4*DAC_W-1 downto 0));
  end component;
  
end package;

library ieee;
use ieee.std_logic_1164.all;
entity gen_cipher is

  generic (
    LEN_W: in integer;
    CP: in std_logic_vector;
    M_MAX: in integer;     -- 8
    LOG2M_MAX: in integer; -- 3
    LOG2M_W: in integer;   -- 2
    DAC_W: in integer);    -- 16
  port (
    clk : in std_logic;
    rst : in std_logic;
    osamp_min1     : in std_logic_vector(1 downto 0); -- 0=1, 1=2, or 3=4

    -- when this generates "random" M-PSK symbols, M is determined by
    log2m : in std_logic_vector(LOG2M_W-1 downto 0); -- log2 of M. 1...LOG2M_MAX
    
    -- units of cycles (typ at 308MHz).  Except zero means lots of cycles, not 1.
    len_min1 : in std_logic_vector(LEN_W-1 downto 0);

    lfsr_state_ld  : in  std_logic; -- sampled when go_pulse=1

    lfsr_state_in  : in  std_logic_vector(CP'length-1 downto 0);
    lfsr_state_nxt : out std_logic_vector(CP'length-1 downto 0);
--    lfsr_state_nxt_vld : out std_logic;
    
    go_pulse    : in std_logic;
    -- if go_pulse held high will go uninteruptedly forever,
    -- regardless of len_min1. I think

    en: in std_logic;

--    end_pre : out std_logic; -- high cyc before last valid cycle

    dout_vld     : out std_logic; -- high only during the headers
    dout         : out std_logic_vector(4*DAC_W-1 downto 0));
end gen_cipher;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
use work.lfsr_w_pkg.all;
architecture rtl of gen_cipher is
  

  function useonly(vi: std_logic_vector; nbits: std_logic_vector)
    return std_logic_vector is
    -- desc: masks out LSBs of vi. Allows only nbits to pass thru.
    --       Suppose vi=abcd, and LOG2M_MAX=4.
    --         nbits="001" -> vo=a1000
    --         nbits="010" -> vo=ab100
    --         nbits="011" -> vo=abc10
    --         nbits="100" -> vo=abcd1
    variable vo: std_logic_vector(vi'length downto 0);
    variable kk: unsigned(LOG2M_W-1 downto 0);
  begin
    vo := vi&'0';
    for k in 1 to LOG2M_MAX loop -- 1 to 4
      kk := to_unsigned(k,LOG2M_W);
      if (kk=unsigned(nbits)) then
        vo(vi'length-k) := '1';
      elsif (kk>unsigned(nbits)) then
        vo(vi'length-k) := '0';
      end if;
    end loop;
    return vo;
  end function useonly;


  signal ctr: std_logic_vector(LEN_W-1 downto 0) := (others=>'0');

  signal ctr_atlim, lsfr_rst, lfsr_en,
    lfsr_rst, ctr_en, ctr_en_d
    : std_logic:='0';

  signal lfsr_data: std_logic_vector(4*LOG2M_MAX-1 downto 0);

  signal lfsr4_state_nxt, lfsr2_state_nxt, lfsr1_state_nxt:
    std_logic_vector(CP'length-1 downto 0);
  
  type sym_array_t is array(0 to 3) of std_logic_vector(LOG2M_MAX downto 0);
  signal mskd_a: sym_array_t;
  signal osamped:  std_logic_vector((LOG2M_MAX+1)*4-1 downto 0);

  
begin

  lfsr_rst <= rst or (go_pulse and lfsr_state_ld);
  lfsr_en  <= (go_pulse or (ctr_en and not ctr_atlim)) and en;
  lfsr: lfsr_w
    generic map(
      W  => 4*LOG2M_MAX,
      CP => CP)
    port map(
      en  => lfsr_en,
      
      d_i => (others=>'0'),
      ld  => '0',

      rst_st    => lfsr_state_in, 
      rst       => lfsr_rst,
      state_nxt => lfsr_state_nxt,

      d_o       => lfsr_data,
      
      clk       => clk);

--  lfsr_state_nxt_vld <= ctr_atlim;

  gen_4samps: for k in 0 to 3 generate

    -- The lfsr produces 4*LOG2M_MAX bits every cycle.
    -- but here we discard some and use only 4*log2m
    mskd_a(k) <= useonly(lfsr_data(LOG2M_MAX*(k+1)-1 downto LOG2M_MAX*k), log2m);

    dout((k+1)*DAC_W-1 downto k*DAC_W) <= 
      osamped((LOG2M_MAX+1)*(k+1)-1 downto (LOG2M_MAX+1)*k) & u_rpt('0',DAC_W-1-LOG2M_MAX);
  end generate gen_4samps;


  clk_proc: process(clk) is
  begin
    if (rising_edge(clk)) then
      if (osamp_min1="00") then    -- oversamp by 1
        osamped <= mskd_a(3)&mskd_a(2)&mskd_a(1)&mskd_a(0);
      elsif (osamp_min1="01") then -- oversamp by 2
        osamped <= mskd_a(1)&mskd_a(1)&mskd_a(0)&mskd_a(0);
      else -- oversample by 4
        osamped <= mskd_a(0)&mskd_a(0)&mskd_a(0)&mskd_a(0);
      end if;
      if ((go_pulse and en)='1') then
        ctr       <= len_min1;
        ctr_atlim <= '0'; -- len_min1 may never be zero.
      elsif (ctr_en='1') then
        ctr       <= u_dec(ctr);
        ctr_atlim <= u_b2b(unsigned(ctr)=1);
      end if;
      ctr_en   <= en and (go_pulse or (ctr_en and not ctr_atlim));
      ctr_en_d <= ctr_en;
    end if;
  end process;
  dout_vld <= ctr_en_d;
--  end_pre  <= ctr_en and en and ctr_atlim;
  
end rtl;
  
