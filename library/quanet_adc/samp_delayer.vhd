library ieee;
use ieee.std_logic_1164.all;
package samp_delayer_pkg is
  component samp_delayer is
    generic (
      W: integer);
    port(
      clk: in std_logic;
      din: in std_logic_vector(W*4-1 downto 0);
      dly: in std_logic_vector(1 downto 0);
      dout: out std_logic_vector(W*4-1 downto 0));
  end component;
      
end samp_delayer_pkg;

library ieee;
use ieee.std_logic_1164.all;
entity samp_delayer is
  generic (
    W: integer);
  port (
    clk: in std_logic;
    din: in std_logic_vector(W*4-1 downto 0);
    dly: in std_logic_vector(1 downto 0);
    dout: out std_logic_vector(W*4-1 downto 0));
end samp_delayer;

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
library work;
use work.util_pkg.all;
architecture rtl of samp_delayer is
  signal din_d: std_logic_vector(W*4-1 downto 0);
  signal din_w: std_logic_vector(W*8-1 downto 0);
begin
  din_w(W*4-1 downto   0) <= din_d;
  din_w(W*8-1 downto W*4) <= din;
  process(clk)
  begin
    if (rising_edge(clk)) then
      din_d <= din;
      dout  <= din_w(to_integer(unsigned(dly))*W+4*W-1 downto to_integer(unsigned(dly))*W);
    end if;
  end process;
end architecture rtl;
