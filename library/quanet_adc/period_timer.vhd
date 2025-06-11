


-- generates time signals for consecutive periodic pulses,
-- either a finite or infinite number them.
-- These signals are of the form:
--
-- pd_qty_min1   2
-- go            _____-____________________________
-- going         ______------------------------____
-- pd_first      ______--------____________________
-- pd_start      ______-_______-_______-___________
-- pd_end        _____________-_______-_______-____
-- pd_last       ______________________--------____
-- cyc_ctr             012345670123456701234567

--
-- The period length is in units of cycles.
-- There are four adc samps per cycle.
-- (for 100km link this might be 100k/2e8*1.23G/4 = 30833 = x7871 )
-- Or it could be a QSDC packet duration (maybe 1us*1.23G/4 = 308)

-- If the counter "free runs", the periods do not start immediately.
-- 
-- go            __-________
-- go_pend      ____----____
-- go_i              __-____
-- going        ________------------------------____________
-- cyc_ctr      012345670123456701234567012345670123456701234
-- cyc_ctr_atlim ______-_______-_______-_______-_______-_____
-- ctc_ctr              222222221111111100000000
-- pd_first      _______--------____________________________
-- pd_start      _______-_______-_______-___________________
-- pd_end        ______________-_______-_______-_____
-- pd_last       _______________________--------____________

-- 
-- 
-- go        _-______________________________
-- going     __------------------------______
-- pd_start  __-_______-_______-________________
-- pd_end    _________-_______-_______-_______
-- cyc_ctr     012345670123456701234567
-- ctc_ctr
-- ctr_atlim   __________________---------___
-- pd_last  

-- pd_first ______-_________________________________
-- pd_tx    ______-________-________-_______________


-- if tx_req held high continuously:

library ieee;
use ieee.std_logic_1164.all;
package period_timer_pkg is

  component period_timer is
    generic (
      PD_LEN_W: integer; -- 32
      PD_QTY_W: integer); -- 10
    port (
      clk : in std_logic; -- at baud/4
      rst: in std_logic;
      free_run : in std_logic;
      hold_first_frame: in std_logic;
      pd_len_cycs_min2 : in std_logic_vector(PD_LEN_W-1 downto 0); -- period in clk cycles
      cyc_ctr      : out std_logic_vector(PD_LEN_W-1 downto 0); -- counts 0 on up.
      

      pd_qty_min1 : in std_logic_vector(PD_QTY_W-1 downto 0);
      go   : in std_logic; -- request transission by pulsing high for one cycle
      going        : out std_logic;     -- high during all the periods
      pd_first     : out std_logic;     -- high during first period
      pd_start_pul : out std_logic; -- pulse at start of each period 
      pd_end_pul_pre   : out std_logic; -- pulse at end of each period
      pd_end_pul   : out std_logic; -- pulse at end of each period
      pd_last      : out std_logic);    -- high during last period
  end component;
  
end package;


library ieee;
use ieee.std_logic_1164.all;
entity period_timer is
  generic (
    PD_LEN_W: integer; -- 32
    PD_QTY_W: integer); -- 10
  port (
    clk : in std_logic; -- at baud/4
    rst: in std_logic;
    free_run : in std_logic;

    hold_first_frame: in std_logic;
    pd_len_cycs_min2 : in std_logic_vector(PD_LEN_W-1 downto 0); -- period in clk cycles
    pd_qty_min1 : in std_logic_vector(PD_QTY_W-1 downto 0);
    go   : in std_logic; -- request transission by pulsing high for one cycle


    -- control signals indicate when to transmit
    going        : out std_logic;     -- high during all the periods
    cyc_ctr      : out std_logic_vector(PD_LEN_W-1 downto 0);
    pd_first     : out std_logic;     -- high during first period
    pd_start_pul : out std_logic; -- pulse at start of each period 
    pd_end_pul_pre  : out std_logic; -- pulse at end of each period
    pd_end_pul   : out std_logic; -- pulse at end of each period
    pd_last      : out std_logic);    -- high during last period
end period_timer;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
use work.global_pkg.all;
architecture rtl of period_timer is
  signal 
    ctc_ctr_en, cyc_ctr_atlim, cyc_ctr_atlim_pre,
    pd_first_i, pd_last_i, go_i, go_pend, going_i, pd_start_i, pd_end: std_logic := '0';
  signal cyc_ctr_i: std_logic_vector(PD_LEN_W-1 downto 0) := (others=>'0');
  signal pd_ctr_i: std_logic_vector(PD_QTY_W-1 downto 0) := (others=>'0');
begin
  -- b2b stands for "Boolean to Bit".  It's a very useful conversion.

  cyc_ctr_atlim_pre <= u_b2b(cyc_ctr_i = pd_len_cycs_min2);

  -- This pulses hi the cyle before we really go.
  go_i <= not rst and u_if(free_run='1',
               go_pend and ((not going_i or pd_last_i) and cyc_ctr_atlim),
               go      and (not going_i or (pd_last_i and cyc_ctr_atlim)));
  
  clk_proc: process(clk) is
  begin
    if (rising_edge(clk)) then
      if ((rst or cyc_ctr_atlim)='1') then
        cyc_ctr_i <= (others =>'0');
      elsif ((free_run or going_i)='1') then
        cyc_ctr_i <= u_inc(cyc_ctr_i);
      end if;
      cyc_ctr_atlim <= cyc_ctr_atlim_pre;

      go_pend <= not rst and free_run and
                 (go or (go_pend and not go_i));

      if (rst='1') then
        going_i <= '0';
      else
        going_i <= go_i or (going_i and not (pd_last_i and cyc_ctr_atlim));
      end if; 

      -- hi during first cycle
      pd_first_i <= (go_i or pd_first_i) and not (rst or cyc_ctr_atlim);
                                                                        
      pd_start_i <=  go_i or (going_i and cyc_ctr_atlim and not pd_last_i);
      pd_end     <= going_i and cyc_ctr_atlim_pre;
      
      -- count a certain number of frames
      if ((rst or not going_i or hold_first_frame)='1') then
        pd_ctr_i    <= pd_qty_min1;
      elsif ((cyc_ctr_atlim and pd_last_i) ='1') then
        pd_ctr_i    <= pd_qty_min1;
      elsif (cyc_ctr_atlim='1') then
        pd_ctr_i    <= std_logic_vector(unsigned(pd_ctr_i)-1);
      end if;
      
      if ((rst or not going_i)='1') then
        pd_last_i <= u_b2b(unsigned(pd_qty_min1)=0);
      elsif (cyc_ctr_atlim='1') then
        if (pd_last_i='1') then
          pd_last_i <= u_b2b(unsigned(pd_qty_min1)=0);
        else
          pd_last_i <= u_b2b(unsigned(pd_ctr_i)=1);
        end if;
      end if;
      
    end if;
  end process;

  going        <= going_i;
  pd_first     <= pd_first_i;
  pd_start_pul <= pd_start_i;
  pd_end_pul_pre <= going_i and cyc_ctr_atlim_pre;
  pd_end_pul   <= pd_end;
  pd_last      <= pd_last_i;
  cyc_ctr      <= cyc_ctr_i;
end architecture rtl;
