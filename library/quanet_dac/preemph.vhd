

-- implements a simple IIR filter of one coeficient.
-- The coeficient must be of the form 2^^(-N)


library ieee;
use ieee.std_logic_1164.all;
entity preemph is
  generic (
    D_W: in integer;
    CONST_W: in integer);
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    en   : in  std_logic;
    din  : in  std_logic_vector(D_W*4-1 downto 0);
    f    : in  std_logic_vector(CONST_W-1 downto 0);
    dout : out std_logic_vector(D_W*4-1 downto 0)
  );
end preemph;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
architecture rtl of preemph is

  type lane_array_t is array(0 to 3) of std_logic_vector(D_W-1 downto 0);
  signal din_a, pre_a, f_a, g_a, v_a: lane_array_t := (others=>(others=>'0'));

begin

  gen_per_lane: for i in 0 to 3 generate
  begin
  
    din_a(i) <= din(D_W*(i+1)-1 downto D_W*i);
    f_a(i)   <= u_shift_right_s(din_a(i), f);
    g_a(i)   <= u_shift_right_s(pre_a(i), f);
    v_a(i)   <= u_add_s(f_a(i),u_sub_s(pre_a(i),g_a(i)));

    gen_lo: if (i>0) generate
    begin
      pre_a(i) <= v_a(i-1);
    end generate gen_lo;

  end generate gen_per_lane;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst='1') then
        pre_a(0) <= (others=>'0');
      else
        pre_a(0) <= v_a(3);
      end if;
--      if (en='1') then
--        for i in 0 to 3 loop
--          dout(D_W*(i+1)-1 downto D_W*i) <= v_a(i);
--        end loop;
--      else
--      end if;
    end if;
  end process;

  dout <= din;
  
end architecture rtl;

