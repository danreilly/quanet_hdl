
library ieee;
use ieee.std_logic_1164.all;
entity rom_inf is
port(
  clk    : in  std_logic;
  rd     : in  std_logic;
  addr   : in  std_logic_vector(4 downto 0);
  dout   : out std_logic_vector(13 downto 0);
  dout_vld: out std_logic);
end rom_inf;

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
architecture behavioral of rom_inf is
  type rom_t is array(0 to 31) of std_logic_vector(13 downto 0);
  signal rom: rom_t := (
    B"00000000000000", B"11111110000010", B"11111110000100", B"11111110000110",
    B"11111110001000", B"11111110001011", B"11111100001101", B"11111100001111",
    B"11111100010010", B"11111010010101", B"11111010010111", B"11111000011010",
    B"11111000011101", B"11110110011111", B"11110100100010", B"11110010100101",
    B"11110000101000", B"11101110101011", B"11101100101110", B"11101010110001",
    B"11101000110101", B"11100100111000", B"11100010111011", B"11011110111110",
    B"11011011000001", B"11010111000101", B"11010011001000", B"11001111001011",
    B"11001001001110", B"11000101010001", B"10111111010100", B"10111011010111");
  attribute rom_style : string;
  attribute rom_style of rom : signal is "block";
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if (rd = '1') then
        dout <= rom(to_integer(unsigned(addr)));
      end if;
      dout_vld <= rd;
    end if;
  end process;
end behavioral;
