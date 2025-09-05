-- duration_ctr.vhd
-- A simple fast low-resource counter.
-- a single cycle pulse
-- causes a multicycle pulse to follow.

-- basic usage:
--
--   dly_min1 3
--   go_pul   ___-_______
--   sig_o    ____----___
--   ctr          3210
--   ctr_atlim ______-__
--   sig_last _______-___

-- smallest delay
--
--   dly_min1 0
--   go_pul   ___-____
--   sig_o    ____-___
--   sig_last ____-___

-- head on heel situation works:
--
--   dly_min1 3
--   go_pul   ___-___-______
--   sig_o    ____--------__
--   sig_last _______-___-__

-- go pulse is ignored if already in progress:
--
--   dly_min1 3
--   go_pul   ___-_-_____
--   sig_o    ____----___
--   sig_last _______-___




library ieee;
use ieee.std_logic_1164.all;
package duration_ctr_pkg is
  
  component duration_ctr is
  generic (
    LEN_W: integer);
  port (
    clk      : in std_logic;
    rst      : in std_logic;
    go_pul   : in std_logic;
    len_min1 : in std_logic_vector(LEN_W-1 downto 0);
    sig_o    : out std_logic;
    sig_last : out std_logic);
  end component;

end package;


library ieee;
use ieee.std_logic_1164.all;
entity duration_ctr is
  generic (
    LEN_W: integer);
  port (
    clk      : in std_logic;
    rst      : in std_logic;
    go_pul   : in std_logic;
    len_min1 : in std_logic_vector(LEN_W-1 downto 0);
    sig_o    : out std_logic;
    sig_last : out std_logic);
end duration_ctr;
  
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
architecture rtl of duration_ctr is
  signal ctr_atlim, ctr_en: std_logic := '0';
  signal ctr: std_logic_vector(LEN_W-1 downto 0):= (others=>'0');
begin

  clk_proc: process(clk) is
  begin
    if (rising_edge(clk)) then
      ctr_en <= not rst and (
                 go_pul or (ctr_en and not ctr_atlim));
      if ((go_pul and (ctr_atlim or not ctr_en)) ='1') then
        ctr       <= len_min1;
        ctr_atlim <= go_pul and u_b2b(unsigned(len_min1)=0);
      elsif (ctr_en='1') then
        ctr       <= u_dec(ctr);
        ctr_atlim <= u_b2b(unsigned(ctr)=1);
      end if;
      
    end if;
  end process;
  sig_o    <= ctr_en;
  sig_last <= ctr_atlim;
  
end architecture rtl;
