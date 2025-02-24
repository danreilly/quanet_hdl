library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;


-- pd_tic    ______-________-________-________-______
-- tx_req    _-______________________________________
-- tx_pend   __-----_________________________________
-- txing     _______---------------------------______
-- probe_ctr   2222222222222222111111111000000000222222
-- probe_last  -------__________________---------------

-- probe_first ______-_________________________________
-- probe_tx    ______-________-________-_______________


-- if tx_req held high continuously:

-- pd_tic       ______-________-________-________-________-______
-- tx_req       __-----------------------------------------------
-- tx_pend      ___----------------------------------------------
-- txing        _______------------------------------------------
-- probe_ctr      2222222222222222111111111000000000222222222111111
-- probe_last     -------__________________---------_______________
-- probe_first    ______-__________________________-_______________
-- probe_tx       ______-________-________-________-________-_____


entity probe_ctl is
  port (
    clk : in std_logic; -- at baud/4
    rst: in std_logic;

    -- The period counter is free running.
    pd_min1 : in std_logic_vector(G_PROBE_PD_W-1 downto 0); -- in clk cycles
    pd_tic : out std_logic;
    
    tx_always: in std_logic;
    tx_req: in std_logic; -- request transission by pulsing high for one cycle
    probe_qty_min1 : in std_logic_vector(G_PROBE_QTY_W-1 downto 0);

    -- control signals indicate when to transmit
    probe_first : out std_logic;
    probe_tx    : out std_logic; -- pulse at beginning of headers
    txing     : out std_logic); -- remains high during pauses, until after final pause
end probe_ctl;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
architecture rtl of probe_ctl is
  signal pd_ctr_atlim, probe_last, tx_pend, txing_i: std_logic := '0';
  signal pd_ctr: std_logic_vector(G_PROBE_PD_W-1 downto 0) := (others=>'0');
  signal probe_ctr: std_logic_vector(G_PROBE_QTY_W-1 downto 0) := (others=>'0');
begin
  -- b2b stands for "Boolean to Bit".  It's a very useful conversion.
  pd_tic <= pd_ctr_atlim;
  txing <= txing_i;
  clk_proc: process(clk) is
  begin
    if (rising_edge(clk)) then
      if ((rst or pd_ctr_atlim)='1') then
        pd_ctr <= pd_min1;
      else
        pd_ctr <= std_logic_vector(unsigned(pd_ctr)-1);
      end if;
      pd_ctr_atlim <= u_b2b(unsigned(pd_ctr)=1) and not rst;

      tx_pend <= not rst and
                 (tx_req or tx_always or (tx_pend and not pd_ctr_atlim));
      
      txing_i <= not rst and
               (   (tx_pend and pd_ctr_atlim)
                or (txing_i and not (probe_last and pd_ctr_atlim)));


      
      -- transmit a certain number of headers
      if ((rst or not txing_i)='1') then
        probe_ctr     <= probe_qty_min1;
      elsif ((pd_ctr_atlim and probe_last) ='1') then
        probe_ctr     <= probe_qty_min1;
      elsif (pd_ctr_atlim='1') then
        probe_ctr     <= std_logic_vector(unsigned(probe_ctr)-1);
      end if;
      
      if ((rst or (not txing_i and not tx_pend))='1') then
        probe_last <= '1';
      elsif (pd_ctr_atlim='1') then
        if ((probe_last and tx_pend)='1') then -- tx_pre
          probe_last   <= u_b2b(unsigned(probe_qty_min1)=0);          
        elsif ((probe_last and not tx_pend)='1') then
          probe_last   <= '1';
        else
          probe_last   <= u_b2b(unsigned(probe_ctr)=1);
        end if;
      end if;
      
    end if;
  end process;
  probe_first <= pd_ctr_atlim and tx_pend and probe_last;
  probe_tx    <= pd_ctr_atlim and (tx_pend or (txing_i and not probe_last));  
end architecture rtl;
