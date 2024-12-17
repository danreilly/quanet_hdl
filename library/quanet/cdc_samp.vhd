-- cdc_samp.vhd
--
-- Data in one clock domain is simply asynchronously sampled in another.
-- No precautions aganst metastability.
-- 
-- NOTE: you must also add the cdc_samp.xdc constraint to your project,
-- and set its "SCOPED_TO_REF" property to "cdc_samp". (see ug903 p64)

library ieee;
use ieee.std_logic_1164.all;
package cdc_samp_pkg is

  component cdc_samp is
    generic ( W: integer);
    port (
      in_data   : in  std_logic_vector(W-1 downto 0);
      out_data  : out std_logic_vector(W-1 downto 0);
      out_clk   : in  std_logic);
  end component;

end cdc_samp_pkg;




library ieee;
use ieee.std_logic_1164.all;

entity cdc_samp is
  generic ( W: integer);
  port (
    in_data   : in  std_logic_vector(W-1 downto 0);
    out_data  : out std_logic_vector(W-1 downto 0);
    out_clk   : in  std_logic);
end entity cdc_samp;

architecture rtl of cdc_samp is
  signal out_data_i: std_logic_vector(W-1 downto 0) := (others=>'0');

  attribute DONT_TOUCH: string;
  attribute DONT_TOUCH of out_data_i: signal is "TRUE";
begin
  process(out_clk)
  begin
    if (rising_edge(out_clk)) then
      out_data_i <= in_data;
    end if;
  end process;
  out_data <= out_data_i;  
end rtl;
