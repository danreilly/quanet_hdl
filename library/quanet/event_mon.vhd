
-- event monitor
--
-- This counts events in any clock domain
-- for the benefit of the processor.
-- The processer might also want to view the event in a status reg.
-- That is what event_out is for.

library ieee;
use ieee.std_logic_1164.all;
package event_mon_pkg is
  component event_mon is
    port (
      event      : in std_logic;
      event_clk  : in std_logic;

      procclk   : in std_logic; -- clock used for clr_event, typically proc bus clock
      event_out : out std_logic; -- resampled in procclk domain
      saw_event : out std_logic;
      saw_not_event : out std_logic;
      clr       : in std_logic);  -- clears "saw_event".
  end component;
end package;

library ieee;
use ieee.std_logic_1164.all;
entity event_mon is
  port (
    event      : in std_logic;
    event_clk  : in std_logic;

    procclk   : in std_logic; -- clock used for clr_event, typically proc bus clock
    event_out : out std_logic; -- resampled in procclk domain
    saw_event : out std_logic;
    saw_not_event : out std_logic;
    clr       : in std_logic);  -- clears "saw_event".
end event_mon;

use work.cdc_samp_pkg.all;
use work.cdc_pulse_pkg.all;
architecture struct of event_mon is
  signal saw_event_i, saw_not_event_i, clr_ec: std_logic := '0';
begin
    
  process(event_clk)
  begin
    if (rising_edge(event_clk)) then
      if (event='1') then
        saw_event_i <= '1';
      elsif (clr_ec='1') then
        saw_event_i <= '0';
      end if;
      if (event='0') then
        saw_not_event_i <= '1';
      elsif (clr_ec='1') then
        saw_not_event_i <= '0';
      end if;
    end if;
  end process;

  event_samp: cdc_samp
    generic map(W =>3)
    port map(
      in_data(0)  => event,
      in_data(1)  => saw_event_i,
      in_data(2)  => saw_not_event_i,
      out_data(0) => event_out,
      out_data(1) => saw_event,
      out_data(2) => saw_not_event,
      out_clk => procclk);

  clr_pulse: cdc_pulse
    port map(
      in_pulse => clr,
      in_clk   => procclk,
      out_pulse => clr_ec,
      out_clk   => event_clk);
  
end architecture struct;


