library ieee;
use ieee.std_logic_1164.all;

-- tx_commenc  __-------------------------------------
-- frame_sync_qual__-________-________-________-______
-- txing      _______---------------------------______
-- tx_done     _________________________________------
-- frame_ctr    22222222222222111111111000000000222222
-- frame_last   _______________________---------______

-- frame_first_pul__-_________________________________
-- frame_first    ___---------__________________------
-- frame_go    _____-________-________-______________




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

    
    tx_always    : in std_logic;
    tx_indefinite: in std_logic;
    tx_commence  : in std_logic; -- once hi stays hi till teardown
    frame_sync_qual: in std_logic; -- request transission by pulsing high for one cycle

    frame_qty_min1 : in std_logic_vector(FRAME_QTY_W-1 downto 0);

    -- control signals indicate when to transmit
    frame_first     : out std_logic;
    frame_first_pul : out std_logic;
    frame_go        : out std_logic); -- pulse at beginning of headers
--    txing           : out std_logic); -- remains high during pauses, until after final pause
end frame_ctl;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
architecture rtl of frame_ctl is
  signal pd_ctr_atlim, frame_last, tx_pend, txing_i, frame_first_i, tx_done: std_logic := '0';
  signal pd_ctr: std_logic_vector(FRAME_PD_CYCS_W-1 downto 0) := (others=>'0');
  signal frame_ctr: std_logic_vector(FRAME_QTY_W-1 downto 0) := (others=>'0');
begin
  -- b2b stands for "Boolean to Bit".  It's a very useful conversion.
  pd_tic <= pd_ctr_atlim;
--  txing <= txing_i;
  clk_proc: process(clk) is
  begin
    if (rising_edge(clk)) then

      -- This stands alone:
      if ((rst or pd_ctr_atlim)='1') then
        pd_ctr       <= pd_min1;
        pd_ctr_atlim <= u_b2b(unsigned(pd_min1)=0);
      else
        pd_ctr       <= std_logic_vector(unsigned(pd_ctr)-1);
        pd_ctr_atlim <= u_b2b(unsigned(pd_ctr)=1);
      end if;


      -- This stuff below is separate.

--      txing_i <= tx_always or (tx_commence and
--               (   (frame_sync_qual and not tx_done)
--                   or (txing_i and
--                       (tx_indefinite or (not (frame_last and frame_sync_qual))))));
      if (tx_always='1') then
        txing_i <= '1';
      elsif (frame_sync_qual='1') then
        txing_i <= (tx_indefinite or not (frame_last or tx_done)) and
                   tx_commence;
      end if;
      
      tx_done <= not tx_indefinite and not tx_always and tx_commence and
                 ((txing_i and frame_last and frame_sync_qual) or tx_done);
      
      -- transmit a certain number of headers
      if ((not tx_commence or (frame_sync_qual and frame_last))='1') then
        frame_ctr     <= frame_qty_min1;
      elsif (frame_sync_qual='1') then
        frame_ctr     <= u_dec(frame_ctr);
      end if;
      
      if (tx_commence='0') then
        frame_last <= '0';
      elsif (frame_sync_qual='1') then
        if (frame_last='1') then -- tx_pre
          frame_last   <= u_b2b(unsigned(frame_qty_min1)=0);
        else
          frame_last   <= u_b2b(unsigned(frame_ctr)=1);
        end if;
      end if;

      if (frame_sync_qual='1') then
        frame_first_i <= tx_commence and not txing_i and not tx_done;
      end if;
      
      frame_first_pul <= tx_commence and not txing_i and not tx_done and frame_sync_qual;
      
    end if;
  end process;
  frame_first     <= frame_first_i;

  frame_go        <= frame_sync_qual and
                     ((tx_commence and (tx_indefinite or (not frame_last and not tx_done)))
                                 or tx_always);
end architecture rtl;
