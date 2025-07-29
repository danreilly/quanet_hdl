library ieee;
use ieee.std_logic_1164.all;
package small_fixed_dly_pkg is
  
  component small_fixed_dly is
    generic(
      CYC_DLY : integer;
      WORD_W  : integer);
    port (
      clk  : in std_logic;
      din  : in std_logic_vector(WORD_W-1 downto 0);
      dout : out std_logic_vector(WORD_W-1 downto 0));
  end component;
  
end package;

library ieee;
use ieee.std_logic_1164.all;
entity small_fixed_dly is
  generic(
    CYC_DLY : integer;
    WORD_W  : integer);
  port (
    clk  : in std_logic;
    din  : in std_logic_vector(WORD_W-1 downto 0);
    dout : out std_logic_vector(WORD_W-1 downto 0));
end small_fixed_dly;
 
library ieee;
use ieee.std_logic_unsigned.all;
architecture struct of small_fixed_dly is
  type dly_a_t is array(0 to CYC_DLY-1) of std_logic_vector(WORD_W-1 downto 0);
  signal dly_a: dly_a_t :=(others=>(others=>'0')); 
begin
  
  process(clk)
    variable k: integer;
  begin
    if (rising_edge(clk)) then
      dly_a(0) <= din;
      for k in 0 to CYC_DLY-2 loop
        dly_a(k+1)<= dly_a(k);
      end loop;
    end if;
  end process;
  dout <= dly_a(CYC_DLY-1);
  
end architecture struct;
