library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
package decipher_pkg is

 component decipher
  generic (
    M_MAX     : in integer;   -- 4
    LOG2M_MAX : in integer; -- 2
    LOG2M_W:   in integer;   -- 2
    SYMLEN_W: in integer;  -- 10
    BODYLEN_W: in integer;
    CIPHER_W: in integer);
  port (
    clk      : in std_logic;
    prime    : in std_logic;
    en       : in std_logic;
    frame_pulse : in std_logic;
    ii       : in g_adc_samp_array_t;
    iq       : in g_adc_samp_array_t;
    symlen_min1_asamps: in std_logic_vector(SYMLEN_W-1 downto 0);
    body_len_min1_cycs : in std_logic_vector(BODYLEN_W-1 downto 0);
    log2m    : in std_logic_vector(LOG2M_W-1 downto 0); -- 1=2psk, 2=4psk
    cipher_rd : out std_logic;
    cipher   : in std_logic_vector(G_CIPHER_FIFO_D_W-1 downto 0);
    oi       : out g_adc_samp_array_t;
    oq       : out g_adc_samp_array_t);
  end component;

end package;  


library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
entity decipher is
  generic (
    M_MAX     : in integer;   -- 4
    LOG2M_MAX : in integer; -- 2
    LOG2M_W:   in integer;   -- 2
    SYMLEN_W: in integer;  -- 10
    BODYLEN_W: in integer;
    CIPHER_W: in integer);
  port (
    clk    : in std_logic;
    prime  : in std_logic;
    en     : in std_logic;
    frame_pulse : in std_logic;
    ii     : in g_adc_samp_array_t;
    iq     : in g_adc_samp_array_t;
    symlen_min1_asamps: in std_logic_vector(SYMLEN_W-1 downto 0);
    body_len_min1_cycs : in std_logic_vector(BODYLEN_W-1 downto 0);
    log2m  : in std_logic_vector(LOG2M_W-1 downto 0); -- 1=2psk, 2=4psk
    cipher_rd : out std_logic;
    cipher : in std_logic_vector(G_CIPHER_FIFO_D_W-1 downto 0);
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

  signal syms: std_logic_vector(LOG2M_W*4-1 downto 0); -- left aligned
  signal syms_vld: std_logic;
  signal en_d: std_logic:='0';

  signal ctr: std_logic_vector(BODYLEN_W-1 downto 0) := (others=>'0');

  signal ctr_atlim, ctr_en, ctr_en_d
    : std_logic:='0';
  
begin

  assert (to_01(unsigned(log2m))<=4) report "Mpsk for M>4 not implemented yet"
    severity failure;

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
      en    => ctr_en,

      din     => cipher,
      din_r   => cipher_rd,
      
      symlen_min1_asamps => symlen_min1_asamps,
      -- when this component generates M-PSK, M is determined by:
      log2m => log2m,
      
      dout     => syms,
      dout_vld => syms_vld);


  clk_proc: process(clk) is
  begin
    if (rising_edge(clk)) then
      en_d <= en;
      if ((frame_pulse or (ctr_en and ctr_atlim))='1') then
        ctr       <= body_len_min1_cycs;
        ctr_atlim <= '0'; -- len_min1 may never be zero.
      elsif (ctr_en='1') then
        ctr       <= u_dec(ctr);
        ctr_atlim <= u_b2b(unsigned(ctr)=1);
      end if;
      ctr_en   <= en and (frame_pulse or (ctr_en and not ctr_atlim));
      ctr_en_d <= ctr_en;
    end if;
  end process;
--  dout_vld <= ctr_en_d;

  
  gen_quad: for i in 0 to 3 generate
  begin
    c(i) <= syms(LOG2M_W*(i+1)-1 downto LOG2M_W*i);

    clk_per_proc: process(clk) is
    begin
      if (rising_edge(clk)) then
        if ((en='1') and (c(i)="11")) then -- -3pi/2
          oi(i) <= iq(i);
          oq(i) <= u_neg(ii(i));
        elsif ((en='1') and (c(i)="10")) then -- -pi
          oi(i) <= u_neg(ii(i));
          oq(i) <= u_neg(iq(i));
        elsif ((en='1') and (c(i)="01")) then -- -pi/2
          oi(i) <= u_neg(iq(i));
          oq(i) <= ii(i);
        else -- 0;
          oi(i) <= ii(i);
          oq(i) <= iq(i);
        end if;
      end if;
    end process;

  end generate gen_quad;

end architecture rtl;
