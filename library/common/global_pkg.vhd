library ieee;
use ieee.std_logic_1164.all;

package global_pkg is

  -- every hdr_period cycles, a header can be transmitted
  constant G_HDR_PD_W : integer := 24;

  -- The transmit stuff (util_dacfifo) is clocked at a max of 308MHz,
  -- and processes at most four symbols per cycle.
  -- The length of the header is in units of 4-symbols.
  -- (if using on-off modulation, 1 symbol = 1 bit).
  constant G_HDR_LEN_W : integer := 6;

  -- we can oversample by the factor osamp
  constant G_OSAMP_W : integer := 2;

  -- hdr_qty is the number of headers to transmit consecutively.
  constant G_HDR_QTY_W : integer := 16;
  
end global_pkg;

package body global_pkg is
end global_pkg;
