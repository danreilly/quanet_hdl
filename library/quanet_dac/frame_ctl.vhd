library ieee;
use ieee.std_logic_1164.all;


-- pd_tic    ______-________-________-________-______
-- tx_req    _-______________________________________
-- tx_pend   __-----_________________________________
-- txing     _______---------------------------______
-- frame_ctr   2222222222222222111111111000000000222222
-- frame_last  -------__________________---------------

-- frame_first ______-_________________________________
-- frame_tx    ______-________-________-_______________


-- if tx_req held high continuously:

-- pd_tic       ______-________-________-________-________-______
-- tx_req       __-----------------------------------------------
-- tx_pend      ___----------------------------------------------
-- txing        _______------------------------------------------
-- frame_ctr      2222222222222222111111111000000000222222222111111
-- frame_last     -------__________________---------_______________
-- frame_first    ______-__________________________-_______________
-- frame_tx       ______-________-________-________-________-_____


entity frame_ctl is
  generic (
    FRAME_PD_CYCS_W: in integer;
    FRAME_QTY_W: in integer);
  port (
    clk : in std_logic; -- at baud/4
    rst: in std_logic;

    -- The period counter is free running.
    pd_min1 : in std_logic_vector(FRAME_PD_CYCS_W-1 downto 0); -- in clk cycles
    pd_tic : out std_logic;
    
    tx_always: in std_logic;
    tx_req: in std_logic; -- request transission by pulsing high for one cycle

    frame_qty_min1 : in std_logic_vector(FRAME_QTY_W-1 downto 0);

    -- control signals indicate when to transmit
    frame_first : out std_logic;
    frame_tx    : out std_logic; -- pulse at beginning of headers
    txing     : out std_logic); -- remains high during pauses, until after final pause
end frame_ctl;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
architecture rtl of frame_ctl is
  signal pd_ctr_atlim, frame_last, tx_pend, txing_i: std_logic := '0';
  signal pd_ctr: std_logic_vector(FRAME_PD_CYCS_W-1 downto 0) := (others=>'0');
  signal frame_ctr: std_logic_vector(FRAME_QTY_W-1 downto 0) := (others=>'0');
begin
  -- b2b stands for "Boolean to Bit".  It's a very useful conversion.
  pd_tic <= pd_ctr_atlim;
  txing <= txing_i;
  clk_proc: process(clk) is
  begin
    if (rising_edge(clk)) then
      if ((rst or pd_ctr_atlim)='1') then
        pd_ctr       <= pd_min1;
        pd_ctr_atlim <= u_b2b(unsigned(pd_min1)=0);
      else
        pd_ctr       <= std_logic_vector(unsigned(pd_ctr)-1);
        pd_ctr_atlim <= u_b2b(unsigned(pd_ctr)=1);
      end if;

      tx_pend <= not rst and
                 (tx_req or tx_always or (tx_pend and not pd_ctr_atlim));
      
      txing_i <= not rst and
               (   (tx_pend and pd_ctr_atlim)
                or (txing_i and not (frame_last and pd_ctr_atlim)));


      
      -- transmit a certain number of headers
      if ((rst or not txing_i)='1') then
        frame_ctr     <= frame_qty_min1;
      elsif ((pd_ctr_atlim and frame_last) ='1') then
        frame_ctr     <= frame_qty_min1;
      elsif (pd_ctr_atlim='1') then
        frame_ctr     <= u_dec(frame_ctr);
      end if;
      
      if ((rst or (not txing_i and not tx_pend))='1') then
        frame_last <= '1';
      elsif (pd_ctr_atlim='1') then
        if ((frame_last and tx_pend)='1') then -- tx_pre
          frame_last   <= u_b2b(unsigned(frame_qty_min1)=0);          
        elsif ((frame_last and not tx_pend)='1') then
          frame_last   <= '1';
        else
          frame_last   <= u_b2b(unsigned(frame_ctr)=1);
        end if;
      end if;
      
    end if;
  end process;
  frame_first <= pd_ctr_atlim and tx_pend and frame_last;
  frame_tx    <= pd_ctr_atlim and (tx_pend or (txing_i and not frame_last));  
end architecture rtl;
