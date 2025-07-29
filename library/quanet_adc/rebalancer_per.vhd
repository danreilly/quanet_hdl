-- rebalancer
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
package rebalancer_pkg is
  
  component rebalancer is
    generic (
      ADC_W: integer := 12;
      OFF_W: integer := 8;
      MULT_W: integer := 8);
    port (
      clk: in std_logic;
      i_in: in std_logic_vector(ADC_W-1 downto 0);
      q_in: in std_logic_vector(ADC_W-1 downto 0);
      
      i_offset: in std_logic_vector(OFF_W-1 downto 0);
      q_offset: in std_logic_vector(OFF_W-1 downto 0);
      
      -- 2x2 matrix
      -- elements are fixed precision.  lower MULT_W-2 are < 1.
      m11: in std_logic_vector(MULT_W-1 downto 0);
      m12: in std_logic_vector(MULT_W-1 downto 0);
      m21: in std_logic_vector(MULT_W-1 downto 0);
      m22: in std_logic_vector(MULT_W-1 downto 0);

      i_out: out std_logic_vector(ADC_W-1 downto 0);
      q_out: out std_logic_vector(ADC_W-1 downto 0));
  end component;

end rebalancer_pkg;


library ieee;
use ieee.std_logic_1164.all;
entity rebalancer_per is
  generic (
    ADC_W: integer;
    OFF_W: integer;
    MULT_W: integer);
  port (
    clk: in std_logic;
    i_in: in std_logic_vector(ADC_W-1 downto 0);
    q_in: in std_logic_vector(ADC_W-1 downto 0);
    
    i_offset: in std_logic_vector(OFF_W-1 downto 0);
    q_offset: in std_logic_vector(OFF_W-1 downto 0);
    
    -- 2x2 matrix
    -- elements are fixed precision.  lower MULT_W-2 are < 1.
    m11: in std_logic_vector(MULT_W-1 downto 0);
    m12: in std_logic_vector(MULT_W-1 downto 0);
    m21: in std_logic_vector(MULT_W-1 downto 0);
    m22: in std_logic_vector(MULT_W-1 downto 0);

    i_out: out std_logic_vector(ADC_W-1 downto 0);
    q_out: out std_logic_vector(ADC_W-1 downto 0));
end rebalancer_per;

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
library work;
use work.global_pkg.all;
use work.util_pkg.all;
architecture rtl of rebalancer_per is

  component imbal_mult
    port (
      clk: std_logic;
        A: in std_logic_vector(13 downto 0);
        B: in std_logic_vector(7 downto 0);
        P: out std_logic_vector(21 downto 0));
  end component imbal_mult;


  signal i_d, q_d: std_logic_vector(ADC_W-1 downto 0);
  signal p11,p12,p21,p22: std_logic_vector(21 downto 0);
  
begin

  process(clk)
  begin
    if (rising_edge(clk)) then
      -- This adds offset clamping to the max
      i_d <= u_add_s_clamp(i_in, i_offset);
      q_d <= u_add_s_clamp(q_in, q_offset);

      i_out <= u_add_s_clamp(u_clamp_s(p11(21 downto 6), ADC_W),
                             u_clamp_s(p12(21 downto 6), ADC_W));
      q_out <= u_add_s_clamp(u_clamp_s(p21(21 downto 6), ADC_W),
                             u_clamp_s(p22(21 downto 6), ADC_W));
    end if;
  end process;
  
    mult_11: imbal_mult
      port map(
        clk => clk,
        A => i_d,
        B => m11,
        P => p11);
    mult_12: imbal_mult
      port map(
        clk => clk,
        A => q_d,
        B => m12,
        P => p12);
    mult_21: imbal_mult
      port map(
        clk => clk,
        A => i_d,
        B => m21,
        P => p21);
    mult_22: imbal_mult
      port map(
        clk => clk,
        A => q_d,
        B => m22,
        P => p22);

end architecture rtl;
    
