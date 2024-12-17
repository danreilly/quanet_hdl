
-- use with cdc_thru.xdc 
-- and set its "SCOPED_TO_REF" property to "cdc_thru". (see ug903 p64)

library ieee;
use ieee.std_logic_1164.all;
package cdc_thru_pkg is

  component cdc_thru is
    generic ( W: integer);
    port (
      in_data   : in  std_logic_vector(W-1 downto 0);
      out_data  : out std_logic_vector(W-1 downto 0));
  end component;

end cdc_thru_pkg;



library ieee;
use ieee.std_logic_1164.all;
entity cdc_thru is
  generic ( W: integer);
  port (
    in_data   : in  std_logic_vector(W-1 downto 0);
    out_data  : out std_logic_vector(W-1 downto 0));
end entity cdc_thru;

architecture rtl of cdc_thru is
  attribute DONT_TOUCH: string;
  attribute DONT_TOUCH of out_data: signal is "TRUE";
begin
  out_data <= in_data;
end rtl;
