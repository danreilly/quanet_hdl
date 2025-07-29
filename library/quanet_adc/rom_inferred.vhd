



library ieee;
use ieee.std_logic_1164.all;

entity rom_inf is
port(
  clk  : in  std_logic;
  en   : in  std_logic;
  addr : in  std_logic_vector(5 downto 0);
  data : out std_logic_vector(19 downto 0));

end rom_inf;

use ieee.std_logic_unsigned.all;

architecture behavioral of rom_inf is
  attribute rom_style : string;
  attribute rom_style of ROM : signal is "block";
  type rom_t is array(0 to 31) of std_logic_vector(15 downto 0);
  signal rom rom: rom_t := (
    X"FF00", X"FF04", X"FF08", X"FF0D", X"FE11", X"FE16", X"FE1A", X"FD1F",
    X"FC24", X"FC29", X"FB2E", X"FA34", X"F839", X"F73F", X"F645", X"F44B",
    X"F251", X"F057", X"ED5D", X"EB63", X"E86A", X"E570", X"E276", X"DE7D",
    X"DB83", X"D78A", X"D290", X"CE96", X"C99D", X"C4A3", X"BFA9", X"BAAF");
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if (en = '1') then
        data <= rom(conv_integer(unsigned(addr)));
      end if;
    end if;
  end process;
end behavioral;
