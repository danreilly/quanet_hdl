library ieee;
use ieee.std_logic_1164.all;
package XX_pkg is
  
  component XX is
    generic(
      WORD_W  : integer);
    port (
      clk  : in std_logic
     );
  end component;
  
end package;

library ieee;
use ieee.std_logic_1164.all;
entity XX is
  generic(
    WORD_W  : integer);
  port (
    clk  : in std_logic
    );
end XX;
 
library ieee;
use ieee.std_logic_unsigned.all;
architecture struct of XX is
begin
  
  process(clk)
  begin
    if (rising_edge(clk)) then

    end if;
  end process;
  
end architecture struct;
