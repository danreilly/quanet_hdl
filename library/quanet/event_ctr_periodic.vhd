
-- Typically used to count statistics for the processor, sometimes for debug.
-- counts number of events (ones on event port) occuring per period.
--
-- transfers them to another (typically the processor's) clock domain.


library ieee;
use ieee.std_logic_1164.all;
package event_ctr_periodic_pkg is

  component event_ctr_periodic is
  generic (
    W: integer);
  port (
    clk          : in std_logic;
    event        : in std_logic;
    periodic_pul : in std_logic; -- in clk domain
    
    rclk   : in std_logic; -- typically processor or axi bus clk.
    ctr    : out std_logic_vector(W-1 downto 0)); -- in clk domain
  end component;

end event_ctr_periodic_pkg;

library ieee;
use ieee.std_logic_1164.all;

entity event_ctr_periodic is
  generic (
    W: integer);
  port (
    clk          : in std_logic;
    event        : in std_logic;
    periodic_pul : in std_logic; -- in clk domain
    
    rclk   : in std_logic; -- typically proc clk.
    ctr    : out std_logic_vector(W-1 downto 0));
end event_ctr_periodic;

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.util_pkg.all;
use work.cdc_pulse_pkg.all;
-- use work.cdc_samp_pkg.all;
use work.cdc_thru_pkg.all;
  
architecture struct of event_ctr_periodic is
  signal ctr_l, ctr_uc, ctr_still, ctr_i: std_logic_vector(W-1 downto 0) := (others=>'0');
  signal clr_pc, req_tog, req_c, req_d,
    periodic_pul_rclk, ctr_atlim: std_logic :='0';
begin

  process(clk)
  begin
    if (rising_edge(clk)) then
      if (periodic_pul='1') then
        ctr_still <= ctr_l;
        ctr_l     <= u_rpt('0',W-1)&event;
        ctr_atlim <= '0';
      elsif ((event and not ctr_atlim)='1') then
        ctr_l <= u_inc(ctr_l);
        if (unsigned(not ctr_l(W-1 downto 1))=0) then
          ctr_atlim <= '1';
        else
          ctr_atlim <= '0';
        end if;
      end if;
    end if;
  end process;

  pd_cdc_pul: cdc_pulse
    port map(
      in_pulse  => periodic_pul,
      in_clk    => clk,
      out_pulse => periodic_pul_rclk,
      out_clk   => rclk);

  ctr_thru: cdc_thru
    generic map(W=>W)
    port map(
      in_data  => ctr_still,
      out_data => ctr_uc);
  
  process(rclk)
  begin
    if (rising_edge(rclk)) then
      if (periodic_pul_rclk='1') then
        ctr_i <= ctr_uc;
      end if;
    end if;
  end process;
  ctr <= ctr_i;
  
end architecture struct;
    

