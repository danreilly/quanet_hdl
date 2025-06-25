-- a delayer for pulses
-- in which two input pulses do not occur 
-- any closer than the maximum delay.

library ieee;
use ieee.std_logic_1164.all;
package pulse_dly_pkg is
  
  component pulse_dly is
  generic (
    DLY_W: integer);
  port (
    clk      : in std_logic;
    pul_i    : in std_logic;
    dly_is0  : in std_logic; -- overrides dly_min1
    dly_min1 : in std_logic_vector(DLY_W-1 downto 0);
    pul_o    : out std_logic;
    rst      : in std_logic);
  end component;

end package;


library ieee;
use ieee.std_logic_1164.all;
entity pulse_dly is
generic (
  DLY_W: integer);
port (
    clk      : in std_logic;
    pul_i    : in std_logic;
    dly_is0  : in std_logic; -- overrides dly_min1
    dly_min1 : in std_logic_vector(DLY_W-1 downto 0);
    pul_o    : out std_logic;
    rst      : in std_logic);
end pulse_dly;
  
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
architecture rtl of pulse_dly is
  signal ctr_atlim, ctr_en: std_logic := '0';
  signal ctr: std_logic_vector(DLY_W-1 downto 0):= (others=>'0');
begin

  clk_proc: process(clk) is
  begin
    if (rising_edge(clk)) then
      ctr_en <= pul_i
                or (ctr_en and not ctr_atlim and not rst and not dly_is0);
      if (pul_i='1') then
        ctr       <= dly_min1;
        ctr_atlim <= u_b2b(unsigned(dly_min1)=0);
      elsif (ctr_en='1') then
        ctr       <= u_dec(ctr);
        ctr_atlim <= u_b2b(unsigned(ctr)=1);
      end if;
    end if;
  end process;
  pul_o <= u_if(dly_is0='1', pul_i, ctr_atlim);
  
end architecture rtl;
