-- rebalancer_quad
--
-- Does IQ Imbalance correction.
-- corrects imperfection of optical hybrid
-- and difference in detector efficiencies and amplifier gains.
-- Computes:
--
-- [ I_out]   [ m11 m12 ]   [ I + i_offset ]
-- [ Q_out] = [ m21 m22 ] * [ Q + q_offset ]
--

library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
package rebalancer_quad_pkg is
  
  component rebalancer_quad is
    generic (
      OFF_W: integer;
      MULT_W: integer);
    port (
      clk: in std_logic;
      in_i: in g_adc_samp_array_t;
      in_q: in g_adc_samp_array_t;
      
      i_offset: in std_logic_vector(OFF_W-1 downto 0);
      q_offset: in std_logic_vector(OFF_W-1 downto 0);
      
      -- 2x2 matrix
      -- elements are signed fixed precision.  lower MULT_W-2 are < 1.
      m11: in std_logic_vector(MULT_W-1 downto 0);
      m12: in std_logic_vector(MULT_W-1 downto 0);
      m21: in std_logic_vector(MULT_W-1 downto 0);
      m22: in std_logic_vector(MULT_W-1 downto 0);

      out_i: out g_adc_samp_array_t;
      out_q: out g_adc_samp_array_t);
  end component;

end rebalancer_quad_pkg;


library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
entity rebalancer_quad is
    generic (
      OFF_W: integer;
      MULT_W: integer);
    port (
      clk: in std_logic;
      in_i: in g_adc_samp_array_t;
      in_q: in g_adc_samp_array_t;
      
      i_offset: in std_logic_vector(OFF_W-1 downto 0);
      q_offset: in std_logic_vector(OFF_W-1 downto 0);
      
      -- 2x2 matrix
      -- elements are fixed precision.  lower MULT_W-2 are < 1.
      m11: in std_logic_vector(MULT_W-1 downto 0);
      m12: in std_logic_vector(MULT_W-1 downto 0);
      m21: in std_logic_vector(MULT_W-1 downto 0);
      m22: in std_logic_vector(MULT_W-1 downto 0);

      out_i: out g_adc_samp_array_t;
      out_q: out g_adc_samp_array_t);
end rebalancer_quad;

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
library work;
use work.global_pkg.all;
use work.util_pkg.all;
architecture rtl of rebalancer_quad is

  component rebalancer is
    generic (
      WORD_W: integer;
      OFF_W: integer;
      MULT_W: integer);
    port (
      clk: in std_logic;
      in_i: in std_logic_vector(WORD_W-1 downto 0);
      in_q: in std_logic_vector(WORD_W-1 downto 0);
      
      i_offset: in std_logic_vector(OFF_W-1 downto 0);
      q_offset: in std_logic_vector(OFF_W-1 downto 0);
      
      -- 2x2 matrix
      -- elements are fixed precision.  lower MULT_W-2 are < 1.
      m11: in std_logic_vector(MULT_W-1 downto 0);
      m12: in std_logic_vector(MULT_W-1 downto 0);
      m21: in std_logic_vector(MULT_W-1 downto 0);
      m22: in std_logic_vector(MULT_W-1 downto 0);

      out_i: out std_logic_vector(WORD_W-1 downto 0);
      out_q: out std_logic_vector(WORD_W-1 downto 0));
  end component;

  
begin
  
  gen_quad: for i in 0 to 3 generate
  begin
    
    rebal_i: rebalancer
      generic map(
        WORD_W => 14,
        OFF_W  => OFF_W,
        MULT_W => MULT_W)
      port map(
        clk => clk,
        in_i => in_i(i),
        in_q => in_q(i),
        i_offset => i_offset,
        q_offset => q_offset,
        m11 => m11,
        m21 => m21,
        m12 => m12,
        m22 => m22,
        out_i => out_i(i),
        out_q => out_q(i));

  end generate gen_quad;

end architecture rtl;
    
