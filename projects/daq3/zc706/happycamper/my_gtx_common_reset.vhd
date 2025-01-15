library ieee;
use ieee.std_logic_1164.all;

entity my_gtx_common_reset is 
  generic (
    STABLE_CLOCK_PERIOD      : integer := 8        -- Period of the stable clock driving this state-machine, unit is [ns]
   );
  port (    
    STABLE_CLOCK             : in std_logic;             --Stable Clock, either a stable clock from the PCB
    SOFT_RESET               : in std_logic;               --User Reset, can be pulled any time
    COMMON_RESET             : out std_logic:= '0'  --Reset QPLL
    );
end my_gtx_common_reset;



library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
--use std.textio.all;
--use ieee.std_logic_textio.all;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

architecture RTL of my_gtx_common_reset is


  constant STARTUP_DELAY        : integer := 500;--AR43482: Transceiver needs to wait for 500 ns after configuration
  constant WAIT_CYCLES          : integer := STARTUP_DELAY / STABLE_CLOCK_PERIOD; -- Number of Clock-Cycles to wait after configuration
  constant WAIT_MAX             : integer := WAIT_CYCLES + 10;                    -- 500 ns plus some additional margin


  signal init_wait_count  : std_logic_vector(7 downto 0) :=(others => '0');
  signal init_wait_done   : std_logic :='0';
  signal common_reset_asserted   : std_logic :='0';
  signal common_reset_i   : std_logic ;

  type rst_type is(
    INIT, ASSERT_COMMON_RESET);
    
  signal state : rst_type := INIT;

begin
  process(STABLE_CLOCK)
  begin
    if rising_edge(STABLE_CLOCK) then
      -- The counter starts running when configuration has finished and 
      -- the clock is stable. When its maximum count-value has been reached,
      -- the 500 ns from Answer Record 43482 have been passed.
      if init_wait_count = WAIT_MAX then
        init_wait_done <= '1';
      else
        init_wait_count <= init_wait_count + 1;
      end if;
    end if;
  end process;

  process(STABLE_CLOCK)
  begin
    if rising_edge(STABLE_CLOCK) then
      if(SOFT_RESET = '1') then
        state                <= INIT;
        common_reset_asserted   <= '0';
        COMMON_RESET   <= '0';
      else
        
        case state is
          when INIT => 
            if init_wait_done = '1' then
              state        <= ASSERT_COMMON_RESET;
            end if;
            
          when ASSERT_COMMON_RESET =>
             if common_reset_asserted = '0' then
                COMMON_RESET          <= '1';
                common_reset_asserted  <= '1';
              else
                COMMON_RESET          <= '0';
              end if;
           when OTHERS =>
            state   <= INIT;
         end case;
       end if;
    end if;
  end process;
 

end RTL; 
