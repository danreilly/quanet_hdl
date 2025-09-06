
-- Normally Decipher passes i&q values unchanged,
-- but when "enabled", it deciphers them.
--
-- en_pre     ___----__   (input)
-- ii&qq          vvvv    (input)
-- syms           ssss
-- oi&oq           vvvv
-- o_vld      _____----__

library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
package decipher_pkg is

 component decipher
  generic (
    M_MAX     : in integer; -- 4
    LOG2M_MAX : in integer; -- 2
    LOG2M_W   : in integer; -- 2
    SYMLEN_W  : in integer; -- 10
    FRAME_PD_W: in integer;
    CIPHER_W  : in integer);
  port (
    clk      : in std_logic;
    prime    : in std_logic;
    en_pre : in std_logic;
    ii       : in g_adc_samp_array_t;
    iq       : in g_adc_samp_array_t;
    symlen_min1_asamps: in std_logic_vector(SYMLEN_W-1 downto 0);
    log2m    : in std_logic_vector(LOG2M_W-1 downto 0); -- 1=2psk, 2=4psk
    cipher_rd : out std_logic;
    cipher   : in std_logic_vector(CIPHER_W-1 downto 0);
    o_vld  : out std_logic;
    oi       : out g_adc_samp_array_t;
    oq       : out g_adc_samp_array_t);
  end component;

end package;  


library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
use work.duration_ctr_pkg.all;
entity decipher is
  generic (
    M_MAX     : in integer;   -- 4
    LOG2M_MAX : in integer; -- 2
    LOG2M_W:   in integer;   -- 2
    SYMLEN_W: in integer;  -- 10
    FRAME_PD_W: in integer;
    CIPHER_W: in integer);
  port (
    clk        : in std_logic;
    prime      : in std_logic;
    en_pre : in std_logic;
    ii     : in g_adc_samp_array_t;
    iq     : in g_adc_samp_array_t;
    symlen_min1_asamps: in std_logic_vector(SYMLEN_W-1 downto 0);
--    body_len_min1_cycs : in std_logic_vector(FRAME_PD_W-1 downto 0);
    log2m  : in std_logic_vector(LOG2M_W-1 downto 0); -- 1=2psk, 2=4psk
    cipher_rd : out std_logic;
    cipher : in std_logic_vector(CIPHER_W-1 downto 0);
    o_vld  : out std_logic;
    oi     : out g_adc_samp_array_t;
    oq     : out g_adc_samp_array_t);
end decipher;

library ieee;
use ieee.numeric_std.all;
use work.util_pkg.all;
use work.symbol_reader_pkg.all;
architecture rtl of decipher is
  type cipher_array_t is array(0 to 3) of std_logic_vector(LOG2M_W-1 downto 0);
  signal c: cipher_array_t;

  signal syms: std_logic_vector((LOG2M_W+1)*4-1 downto 0); -- left aligned
  signal syms_vld, frame_ctr_last, frame_pulse, frame_ctr_rst: std_logic := '0';
  signal en_d, go_i: std_logic:='0';

  signal ctr: std_logic_vector(FRAME_PD_W-1 downto 0) := (others=>'0');

--  signal ctr_atlim, ctr_en : std_logic:='0';

--  type wide_adc_samp_array_t is array(0 to 7) of std_logic_vector(G_ADC_SAMP_W-1 downto 0);
--  signal ii_wide, iq_wide: wide_adc_samp_array_t := (others=>(others=>'0'));
--  signal di, dq: g_adc_samp_array_t;
  
begin

  assert (to_01(unsigned(log2m))<=4) report "Mpsk for M>4 not implemented yet"
    severity failure;

  -- symbol reader works like:
  --       en ___-___
  --     dout     v
  -- dout_vld ____-__  
  symbol_reader_i: symbol_reader
    generic map(
      M_MAX     => M_MAX,
      LOG2M_MAX => LOG2M_MAX,
      LOG2M_W   => LOG2M_W,
      SYMLEN_W  => SYMLEN_W,
      DIN_W     => CIPHER_W)
    port map(
      clk   => clk,
      rst   => '0',
      prime => prime,
      en    => en_pre,

      din     => cipher,
      din_r   => cipher_rd,
      
      symlen_min1_asamps => symlen_min1_asamps,
      -- when this component generates M-PSK, M is determined by:
      log2m => log2m,
      
      dout     => syms,
      dout_vld => syms_vld);


--  clk_proc: process(clk) is
--  begin
--    if (rising_edge(clk)) then
--      for k in 0 to 3 loop
-- -- This did not simulate, so wierd
-- --        ii_wide(k) <= ii_wide(k+4);
-- --        iq_wide(k) <= iq_wide(k+4);
--        di(k) <= ii_wide(k+to_integer(unsigned(dly_asamps)));
--        dq(k) <= iq_wide(k+to_integer(unsigned(dly_asamps)));
--      end loop;
--    end if;
--  end process;

  gen_quad: for ss in 0 to 3 generate
  begin
    -- ii_wide(ss+4) <= ii(ss);
    -- iq_wide(ss+4) <= iq(ss);
    
    c(ss) <= syms((LOG2M_W+1)*(ss+1)-1 downto (LOG2M_W+1)*ss+1);

    clk_per_subcyc: process(clk) is
    begin
      if (rising_edge(clk)) then
        en_d <= en_pre;
        o_vld <= en_d;
        if ((en_d='0') or (c(ss)="00")) then -- 0
          oi(ss) <= ii(ss);
          oq(ss) <= iq(ss);
        elsif (c(ss)="11") then --       -3pi/2
          oi(ss) <= iq(ss);
          oq(ss) <= u_neg(ii(ss));
        elsif (c(ss)="10") then --          -pi
          oi(ss) <= u_neg(ii(ss));
          oq(ss) <= u_neg(iq(ss));
        else -- if (c(ss)="01") then --   -pi/2
          oi(ss) <= u_neg(iq(ss));
          oq(ss) <= ii(ss);
        end if;
      end if;
    end process;

  end generate gen_quad;

end architecture rtl;
