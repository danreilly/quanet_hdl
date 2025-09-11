
-- supposedly the best way to output a clk

entity clk_obuf is
  port (
    clk : in std_logic;
    clk_p : out std_logic;
    clk_n : out std_logic);
end clk_obuf;

library work;
use work.util_pkg.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
architecture RTL of clk_obuf is
  signal clko: std_logic;
begin
  
  -- Note: ODDR in ultrascale vs 7series is different
  oddr: ODDRE1
    port map(
     C => clk,
     D1 => '0',
     D2 => '1',
     SR => '0',
     Q => clko);
  
  obuf_i: OBUFDS
    port map(
     i  => clko,
     o  => clk_p,
     ob => clk_n);

end;
