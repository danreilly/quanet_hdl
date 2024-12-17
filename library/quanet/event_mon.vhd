library ieee;
use ieee.std_logic_1164.all;

entity event_mon is
  port (
    evnt      : in std_logic;
    saw_event : out std_logic;
    clr_event : in std_logic;  -- typically driven by processor
    clk       : in std_logic); -- clock used for clr_event, typically proc bus clock
end event_mon;

architecture struct of event_mon is
  signal saw_event_l: std_logic := '1';
begin
  process(clk, evnt)
  begin
    if (evnt='1') then
      saw_event_l <= '1';
    elsif (clk'event and clk='1') then
      if (clr_event='1') then
        saw_event_l <= '0';
      end if;
    end if;
    saw_event <= saw_event_l;
  end process;
end architecture struct;


