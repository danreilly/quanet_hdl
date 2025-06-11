
-- used with cdc_pulse.xdc
-- (renaming of pulse_bridge)

-- This conveys a pulse (a one-cycle high signal)
-- or any positive spike
-- from one clock domain to another.
-- The in_clk may be faster or slower than the out_clk.



library ieee;
use ieee.std_logic_1164.all;
package cdc_pulse_pkg is

  component cdc_pulse is
    port (
      in_pulse  : in  std_logic;  -- in some unrelated clk domain
      in_clk    : in  std_logic;  -- in some unrelated clk domain
      out_pulse : out std_logic;  -- in the out_clk domain
      out_clk   : in  std_logic);
  end component;

end cdc_pulse_pkg;


library ieee;
use ieee.std_logic_1164.all;

-- This conveys a pulse (a one-cycle high signal)
-- or any positive spike
-- from one clock domain to another.
-- The in_clk may be faster or slower than the out_clk.



entity cdc_pulse is
  port (
    in_pulse  : in  std_logic;  -- in some unrelated clk domain
    in_clk    : in  std_logic;  -- in some unrelated clk domain
    out_pulse : out std_logic;  -- in the out_clk domain
    out_clk   : in  std_logic
  );
end entity cdc_pulse;

architecture rtl of cdc_pulse is
  signal in_pulse_d, in_tog, in_tog_rc, in_tog_rc_d,
    in_tog_rc_dd, out_pulse_sig: std_logic:= '0';
  attribute ASYNC_REG: string;
  attribute ASYNC_REG of in_tog_rc, in_tog_rc_d: signal is "TRUE";
  attribute DONT_TOUCH: string;
  attribute DONT_TOUCH of in_tog: signal is "TRUE";
begin

  in_tog_proc : process(in_clk) is
  begin
    if (rising_edge(in_clk)) then
      in_pulse_d <= in_pulse;
      in_tog <= in_tog xor (in_pulse and not in_pulse_d);
    end if;
  end process;
  
  out_pulse_proc : process(out_clk) is
  begin
    if (rising_edge(out_clk)) then
      in_tog_rc     <= in_tog; -- maybe mestastable
      in_tog_rc_d   <= in_tog_rc;
      in_tog_rc_dd  <= in_tog_rc_d;
      out_pulse_sig <= in_tog_rc_d xor in_tog_rc_dd;
    end if;
  end process;

  out_pulse <= out_pulse_sig;

end rtl;

      
                                         
                                       
