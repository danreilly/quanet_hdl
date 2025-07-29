-- duration_upctr.vhd
-- A simple fast low-resource counter.
-- a single cycle pulse
-- causes a multicycle pulse to follow.
-- same as duration_ctr,
-- but counts up instead.

-- basic usage:
--
--   dly_min1 3
--   go_pul   ___-_______
--   ctr_en   ____----____
--   ctr       00012341111
--   ctr       00012300000 -- if width cannot contain it.
--   ctr_atlim  _____-__
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
--   ctr          12341234
--   sig_last _______-___-__

-- go pulse is ignored if already in progress:
--
--   dly_min1 3
--   go_pul   ___-_-_____
--   sig_o    ____----___
--   sig_last _______-___




library ieee;
use ieee.std_logic_1164.all;
package duration_upctr_pkg is
  
  component duration_upctr is
  generic (
    LEN_W: integer);
  port (
    clk      : in std_logic;
    rst      : in std_logic;
    go_pul   : in std_logic;
    len_min1 : in std_logic_vector(LEN_W-1 downto 0);
    ctr_o    : out std_logic_vector(LEN_W-1 downto 0);
    sig_o    : out std_logic;
    sig_last : out std_logic);
  end component;

end package;


library ieee;
use ieee.std_logic_1164.all;
entity duration_upctr is
  generic (
    LEN_W: integer);
  port (
    clk      : in std_logic;
    rst      : in std_logic;
    go_pul   : in std_logic;
    len_min1 : in std_logic_vector(LEN_W-1 downto 0);
    ctr_o    : out std_logic_vector(LEN_W-1 downto 0);
    sig_o    : out std_logic;
    sig_last : out std_logic);
end duration_upctr;
  
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
architecture rtl of duration_upctr is
  signal ctr_atlim_pre, ctr_atlim, ctr_en: std_logic := '0';
  signal ctr: std_logic_vector(LEN_W-1 downto 0):= (others=>'0');
begin
  clk_proc: process(clk) is
  begin
    if (rising_edge(clk)) then
      ctr_en <= not rst and (
                 go_pul or (ctr_en and not ctr_atlim));
      if (((go_pul and not ctr_en) or (ctr_en and ctr_atlim_pre))='1') then
        ctr       <= std_logic_vector(to_unsigned(1,LEN_W));
      elsif (ctr_en='1') then
        ctr       <= u_inc(ctr);
      end if;
      ctr_atlim <= u_b2b(ctr=len_min1);
    end if;
  end process;
  sig_last <= ctr_atlim;
  ctr_o    <= ctr;
  sig_o    <= ctr_en;
  
end architecture rtl;
