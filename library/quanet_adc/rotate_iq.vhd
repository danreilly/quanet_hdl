
-- ph_cos and ph_sin are signed fixed precision with TRIG_W-2 bits
-- to the right of the implicit decimal point.
-- So 010000 = 1, 110000 = -1, 001000 = 0.5, etc.

library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
package rotate_iq_pkg is
  
  component rotate_iq is
  generic (
    WORD_W: integer;
    TRIG_W: integer);
  port (
    clk    : in std_logic;
    din_i  : in g_adc_samp_array_t;
    din_q  : in g_adc_samp_array_t;
    ph_cos : in std_logic_vector(TRIG_W-1 downto 0);
    ph_sin : in std_logic_vector(TRIG_W-1 downto 0);
    dout_i : out g_adc_samp_array_t;
    dout_q : out g_adc_samp_array_t);
  end component;
    
end rotate_iq_pkg;

library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
entity rotate_iq is
  generic (
    WORD_W: integer;
    TRIG_W: integer);
  port (
    clk    : in std_logic;
    din_i  : in g_adc_samp_array_t;
    din_q  : in g_adc_samp_array_t;
    ph_cos : in std_logic_vector(TRIG_W-1 downto 0);
    ph_sin : in std_logic_vector(TRIG_W-1 downto 0);
    dout_i : out g_adc_samp_array_t;
    dout_q : out g_adc_samp_array_t);
end rotate_iq;

use work.util_pkg.all;
architecture rtl of rotate_iq is

  component imbal_mult
    port (
      clk: std_logic;
        A: in std_logic_vector(13 downto 0);
        B: in std_logic_vector(7 downto 0);
        P: out std_logic_vector(21 downto 0));
  end component imbal_mult;

  type word_array_t is array(0 to 3) of std_logic_vector(WORD_W-1 downto 0);
  signal ii_a, iq_a, oi_a, oq_a: word_array_t;
  signal ph_sin_neg: std_logic_vector(TRIG_W-1 downto 0);
  constant PROD_W: integer := WORD_W+TRIG_W-1;
  type prod_array_t is array(0 to 3) of std_logic_vector(PROD_W-1 downto 0);
  signal p11, p12, p21, p22: prod_array_t;
  constant H: integer := TRIG_W-3 + WORD_W-1; -- = PROD_W-2
  constant L: integer := TRIG_W-3;
begin
  
  ph_sin_neg <= u_neg(ph_sin);
    
  gen_quad: for k in 0 to 3 generate
  begin

    -- These multipliers assume both A and B are signed,
    -- and P is signed too.
    
    mult_11: imbal_mult
      port map(
        clk => clk,
        A => din_i(k),
        B => ph_cos(TRIG_W-1 downto TRIG_W-8),
        P => p11(k));
    
    mult_12: imbal_mult
      port map(
        clk => clk,
        A => din_q(k),
        B => ph_sin_neg(TRIG_W-1 downto TRIG_W-8),
        P => p12(k));

    mult_21: imbal_mult
      port map(
        clk => clk,
        A => din_i(k), -- signed
        B => ph_sin(TRIG_W-1 downto TRIG_W-8),
        P => p21(k));
    
    mult_22: imbal_mult
      port map(
        clk => clk,
        A => din_q(k),
        B => ph_cos(TRIG_W-1 downto TRIG_W-8),
        P => p22(k));

    process(clk)
      begin
      if (rising_edge(clk)) then
        dout_i(k) <= u_add_s(p11(k)(H downto L),p12(k)(H downto L));
        dout_q(k) <= u_add_s(p21(k)(H downto L),p22(k)(H downto L));
      end if;
    end process;
      
  end generate gen_quad;
  
end architecture rtl;
   
  
