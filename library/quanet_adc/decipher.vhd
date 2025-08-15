library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
package decipher_pkg is

 component decipher
  generic (
    M_MAX     : in integer;   -- 4
    LOG2M_MAX : in integer; -- 2
    LOG2M_W   : in integer;   -- 2
    SYMLEN_W  : in integer;  -- 10
    FRAME_PD_W: in integer;
    CIPHER_W  : in integer);
  port (
    clk      : in std_logic;
    prime    : in std_logic;
    go       : in std_logic; -- a pulse
    en       : in std_logic;
    frame_pd_cycs_min1: in std_logic_vector(FRAME_PD_W-1 downto 0);
    ii       : in g_adc_samp_array_t;
    iq       : in g_adc_samp_array_t;
    dly_asamps: in std_logic_vector(1 downto 0);
    symlen_min1_asamps: in std_logic_vector(SYMLEN_W-1 downto 0);
    body_len_min1_cycs : in std_logic_vector(FRAME_PD_W-1 downto 0);
    log2m    : in std_logic_vector(LOG2M_W-1 downto 0); -- 1=2psk, 2=4psk
    cipher_rd : out std_logic;
    cipher   : in std_logic_vector(G_CIPHER_FIFO_D_W-1 downto 0);
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
    clk    : in std_logic;
    prime  : in std_logic;
    go: in std_logic; -- a pulse
    en     : in std_logic;
    frame_pd_cycs_min1: in std_logic_vector(FRAME_PD_W-1 downto 0);
    ii     : in g_adc_samp_array_t;
    iq     : in g_adc_samp_array_t;
    dly_asamps: in std_logic_vector(1 downto 0);
    symlen_min1_asamps: in std_logic_vector(SYMLEN_W-1 downto 0);
    body_len_min1_cycs : in std_logic_vector(FRAME_PD_W-1 downto 0);
    log2m  : in std_logic_vector(LOG2M_W-1 downto 0); -- 1=2psk, 2=4psk
    cipher_rd : out std_logic;
    cipher : in std_logic_vector(G_CIPHER_FIFO_D_W-1 downto 0);
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

  signal ctr_atlim, ctr_en, ctr_en_d
    : std_logic:='0';

  type wide_adc_samp_array_t is array(0 to 7) of std_logic_vector(G_ADC_SAMP_W-1 downto 0);
  signal ii_wide, iq_wide: wide_adc_samp_array_t := (others=>(others=>'0'));
  signal di, dq: g_adc_samp_array_t;
  
begin

  assert (to_01(unsigned(log2m))<=4) report "Mpsk for M>4 not implemented yet"
    severity failure;

  go_i <= en and not en_d;
  frame_pulse <= go_i or frame_ctr_last;
  frame_ctr: duration_ctr
    generic map (
      LEN_W => FRAME_PD_W)
    port map (
      clk      => clk,
      rst      => prime,
      go_pul   => frame_pulse,
      len_min1 => frame_pd_cycs_min1,
--      sig_o    => 
      sig_last => frame_ctr_last);
  
  
  
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
      ii_wide(0) <= ii_wide(4);
      ii_wide(1) <= ii_wide(5);
      ii_wide(2) <= ii_wide(6);
      ii_wide(3) <= ii_wide(7);

      iq_wide(0) <= iq_wide(4);
      iq_wide(1) <= iq_wide(5);
      iq_wide(2) <= iq_wide(6);
      iq_wide(3) <= iq_wide(7);
      for k in 0 to 3 loop
-- This did not simulate, so wierd!        
--        ii_wide(k) <= ii_wide(k+4);
--        iq_wide(k) <= iq_wide(k+4);
        
        di(k) <= ii_wide(k+to_integer(unsigned(dly_asamps)));
        dq(k) <= iq_wide(k+to_integer(unsigned(dly_asamps)));
      end loop;
      
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
  o_vld <= ctr_en_d;

  gen_quad: for k in 0 to 3 generate
  begin
    ii_wide(k+4) <= ii(k);
    iq_wide(k+4) <= iq(k);
    
    c(k) <= syms((LOG2M_W+1)*(k+1)-1 downto (LOG2M_W+1)*k+1);

    clk_per_proc: process(clk) is
    begin
      if (rising_edge(clk)) then
        if ((ctr_en='0') or (c(k)="00")) then
          oi(k) <= di(k);
          oq(k) <= dq(k);
        elsif (c(k)="11") then -- -3pi/2
          oi(k) <= dq(k);
          oq(k) <= u_neg(di(k));
        elsif (c(k)="10") then -- -pi
          oi(k) <= u_neg(di(k));
          oq(k) <= u_neg(dq(k));
        else -- if (c(k)="01") then -- -pi/2
          oi(k) <= u_neg(dq(k));
          oq(k) <= di(k);
        end if;
      end if;
    end process;

  end generate gen_quad;

end architecture rtl;
