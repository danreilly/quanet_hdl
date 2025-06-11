--  all timepulses last for one refclk period only,
--  and they are all simultaneous:
--
--  us10_pulse __-__-__-__ ... __-__-_
--  us_pulse   __-__-__-__ ... __-__-_
--  ms_pulse   _____-_____ ... __-____
--  s_pulse    _____-_____ ... _______
library ieee;
use ieee.std_logic_1164.all;
package timekeeper_pkg is
  component timekeeper
    generic (
      REF_HZ: real);
    port (
      refclk: in std_logic;
      us_pulse: out std_logic;
      us10_pulse: out std_logic;
      us100_pulse: out std_logic;
      us500_pulse: out std_logic;
      ms_pulse: out std_logic;
      ms100_pulse: out std_logic);
  end component;
end timekeeper_pkg;

library ieee;
use ieee.std_logic_1164.all;
entity timekeeper is
  generic (
    REF_HZ: real);
  port (
    refclk: in std_logic;
    us_pulse: out std_logic;
    us10_pulse: out std_logic;
    us100_pulse: out std_logic;
    us500_pulse: out std_logic;
    ms_pulse: out std_logic;
    ms100_pulse: out std_logic;
    s_pulse: out std_logic);
end timekeeper;

library ieee;
use ieee.std_logic_1164.all;
--dont use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.util_pkg.all;
architecture STRUCTURE of timekeeper is
  constant REFDIV   : integer := integer(REF_HZ / 1.0e6);
  constant REFDIV_W : integer := u_bitwid(REFDIV-1);

  signal us_pulse_l, us10_pulse_l, us100_pulse_l, us500_pulse_l, 
    ms_pulse_l, ms100_pulse_l, s_pulse_l: std_logic := '0';

  signal refclk_ctr: unsigned(REFDIV_W-1 downto 0) := to_unsigned(REFDIV-1, REFDIV_W);
  signal us10_ctr, us100_ctr, us500_ctr, ms_ctr, s_ctr: unsigned(3 downto 0) := to_unsigned(9,4);
  
  signal ms100_ctr: unsigned(6 downto 0) := to_unsigned(99,7);
  
  signal us_pre, us_ctr_atlim: std_logic :='0';
  signal us100_tic, ms_tic, tmr_go, us10_ctr_atlim, us100_ctr_atlim, us500_ctr_atlim,
    ms_ctr_atlim, ms100_ctr_atlim, s_ctr_atlim: std_logic := '0';
  
begin

  us_pulse    <= us_pulse_l;
  us10_pulse  <= us10_pulse_l;
  us100_pulse <= us100_pulse_l;
  us500_pulse <= us500_pulse_l;
  ms_pulse    <= ms_pulse_l;
  ms100_pulse <= ms100_pulse_l;
  s_pulse     <= s_pulse_l;
  
  process(refclk)
  begin
    if (rising_edge(refclk)) then
  
      -- generate us_tic, which pulses once a microsecond
      if (us_pre='1') then
        refclk_ctr <= to_unsigned(REFDIV-1, REFDIV_W);
      else
        refclk_ctr <= refclk_ctr-1;
      end if;
      us_pre <= u_b2b(refclk_ctr=1);
      us_pulse_l <= us_pre;

      -- generate us10_tic, which pulses once every 10 microseconds
      if (us_pre='1') then
        if (us10_ctr_atlim='1') then
          us10_ctr       <= to_unsigned(9,4);
          us10_ctr_atlim <= '0';
        else
          us10_ctr       <= us10_ctr-1;
          us10_ctr_atlim <= u_b2b(us10_ctr=1);
        end if;
      end if;
      us10_pulse_l <= us_pre and us10_ctr_atlim;

      -- generate us100_tic, which pulses once every 100 microseconds
      if ((us_pre and us10_ctr_atlim)='1') then
        if (us100_ctr_atlim='1') then
          us100_ctr       <= to_unsigned(9,4);
          us100_ctr_atlim <= '0';
        else
          us100_ctr       <= us100_ctr-1;
          us100_ctr_atlim <= u_b2b(us100_ctr=1);
        end if;
      end if;
      us100_pulse_l <= us_pre and us10_ctr_atlim and us100_ctr_atlim;

      -- generate us500_tic, which pulses once every 500 microseconds
      if ((us_pre and us10_ctr_atlim and us100_ctr_atlim)='1') then
        if (us500_ctr_atlim='1') then
          us500_ctr       <= to_unsigned(4,4);
          us500_ctr_atlim <= '0';
        else
          us500_ctr       <= us500_ctr-1;
          us500_ctr_atlim <= u_b2b(us500_ctr=1);
        end if;
      end if;
      us500_pulse_l <= us_pre and us10_ctr_atlim and us100_ctr_atlim and us500_ctr_atlim;      
      
      -- generate ms_tic, which pulses once every 1000 microseconds
      if ((us_pre and us10_ctr_atlim and us100_ctr_atlim)='1') then
        if (ms_ctr_atlim='1') then
          ms_ctr       <= to_unsigned(9,4);
          ms_ctr_atlim <= '0';
        else
          ms_ctr       <= ms_ctr-1;
          ms_ctr_atlim <= u_b2b(ms_ctr=1);
        end if;
      end if;
      ms_pulse_l <= us_pre and us10_ctr_atlim and us100_ctr_atlim and ms_ctr_atlim;

      -- generate ms100_pulse, which pulses once every 100ms
      if ((us_pre and us10_ctr_atlim and us100_ctr_atlim and ms_ctr_atlim)='1') then
        if (ms100_ctr_atlim='1') then
          ms100_ctr       <= to_unsigned(99,7);
          ms100_ctr_atlim <= '0';
        else
          ms100_ctr       <= ms100_ctr-1;
          ms100_ctr_atlim <= u_b2b(ms100_ctr=1);
        end if;
      end if;
      ms100_pulse_l <= us_pre and us10_ctr_atlim and us100_ctr_atlim and ms_ctr_atlim and ms100_ctr_atlim;

     -- generate s_pulse, which pulses once every second
      if ((us_pre and us10_ctr_atlim and us100_ctr_atlim and ms_ctr_atlim and ms100_ctr_atlim)='1') then
        if (s_ctr_atlim='1') then
          s_ctr       <= to_unsigned(9,4);
          s_ctr_atlim <= '0';
        else
          s_ctr       <= s_ctr-1;
          s_ctr_atlim <= u_b2b(s_ctr=1);
        end if;
      end if;
      s_pulse_l <= us_pre and us10_ctr_atlim and us100_ctr_atlim and ms_ctr_atlim and ms100_ctr_atlim and s_ctr_atlim;
      
      
    end if;
  end process;
      
end architecture STRUCTURE;
