library ieee;
use ieee.std_logic_1164.all;
package samp_cyc_delayer_pkg is
  component samp_cyc_delayer is
    generic (
      W: integer;
      DLY_W: integer);
    port(
      clk: in std_logic;
      din: in std_logic_vector(W-1 downto 0);
      dly: in std_logic_vector(DLY_W-1 downto 0);
      dout: out std_logic_vector(W-1 downto 0));
  end component;
      
end samp_cyc_delayer_pkg;

library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
entity samp_cyc_delayer is
  generic (
    W: integer;
    DLY_W: integer);
  port (
    clk: in std_logic;
    din: in std_logic_vector(W-1 downto 0);
    dly: in std_logic_vector(DLY_W-1 downto 0);
    dout: out std_logic_vector(W-1 downto 0));
end samp_cyc_delayer;

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
library work;
use work.global_pkg.all;
use work.util_pkg.all;
architecture rtl of samp_cyc_delayer is

  component ad_mem
    generic (
      DATA_WIDTH: integer;
      ADDRESS_WIDTH: integer);
    port (
      clka  : in std_logic;
      wea   : in std_logic;
      addra : in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      dina  : in std_logic_vector(DATA_WIDTH-1 downto 0);

      clkb  : in std_logic;
      reb   : in std_logic;
      addrb : in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      doutb : out std_logic_vector(DATA_WIDTH-1 downto 0));
  end component;

  signal waddr, raddr: std_logic_vector(DLY_W-1 downto 0) := (others=>'0');
  
begin
  
  process(clk)
  begin
    if (rising_edge(clk)) then
      raddr <= u_inc(raddr);
      waddr <= u_add_u(raddr, dly);
    end if;
  end process;

  mem: ad_mem
    generic map(
      DATA_WIDTH => W,
      ADDRESS_WIDTH => DLY_W)
    port map(
      clka  => clk,
      wea   => '1',
      addra => waddr,
      dina  => din,

      clkb  => clk,
      reb   => '1',
      addrb => raddr,
      doutb => dout);
  
end architecture rtl;
