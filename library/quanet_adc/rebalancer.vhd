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
entity rebalancer is
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
end rebalancer;

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
library work;
use work.global_pkg.all;
use work.util_pkg.all;
architecture rtl of rebalancer is

  component imbal_mult
    port (
      clk: std_logic;
        A: in std_logic_vector(13 downto 0);
        B: in std_logic_vector(7 downto 0);
        P: out std_logic_vector(21 downto 0));
  end component imbal_mult;


  constant PROD_W: integer := 22;
  signal d_i, d_q: std_logic_vector(WORD_W-1 downto 0);
  signal p11,p12,p21,p22: std_logic_vector(PROD_W-1 downto 0);
  constant L: integer := MULT_W-2;
  constant H: integer := PROD_W-1;
begin

  process(clk)
  begin
    if (rising_edge(clk)) then
      -- This adds offset clamping to the max
      d_i <= u_add_s_clamp(in_i, i_offset);
      d_q <= u_add_s_clamp(in_q, q_offset);

      out_i <= u_add_s_clamp(u_clamp_s(p11(H downto L), WORD_W),
                             u_clamp_s(p12(H downto L), WORD_W));
      out_q <= u_add_s_clamp(u_clamp_s(p21(H downto L), WORD_W),
                             u_clamp_s(p22(H downto L), WORD_W));
    end if;
  end process;

  -- TODO: set PREG atribute? for "pipelining"
  -- these mults have latency of 3 cycles
  mult_11: imbal_mult
    port map(
      clk => clk,
      A => d_i, -- signed
      B => m11, -- signed
      P => p11);
  mult_12: imbal_mult
    port map(
      clk => clk,
      A => d_q,
      B => m12,
      P => p12);
  mult_21: imbal_mult
    port map(
      clk => clk,
      A => d_i,
      B => m21,
      P => p21);
  mult_22: imbal_mult
    port map(
      clk => clk,
      A => d_q,
      B => m22,
      P => p22);

end architecture rtl;
    
