library ieee;
use ieee.std_logic_1164.all;

package global_pkg is

  -- every probe_pd cycles, a probe can be transmitted
  constant G_PROBE_PD_W : integer := 24;

  -- The transmit stuff (util_dacfifo) is clocked at a max of 308MHz,
  -- and processes at most four symbols per cycle.
  -- The length of the probe is in units cycles at 308.3MHz
  -- (if using on-off modulation, 1 symbol = 1 bit).
  constant G_PROBE_LEN_W : integer := 8;

  -- we can oversample by the factor osamp
  -- though currently the oversampling is fixed.
  constant G_OSAMP_W : integer := 2;

  -- probe_qty is the number of probes to transmit consecutively.
  constant G_PROBE_QTY_W : integer := 16;
  
end global_pkg;

package body global_pkg is
end global_pkg;
