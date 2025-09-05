library ieee;
use ieee.std_logic_1164.all;

-- tx_commenc     _---------------------------
-- frame_sync_qual__-___-___-___-___-___-___-_
-- frame_ctr_en   ____------------____________
-- tx_done        ________________------------
-- frame_ctr      2222222211110000222222222222
-- frame_ctr_is0  ____________----____________
-- frame_ctr_1st  ____----________------------
-- frame_first_pul____-_______________________
-- frame_first    _____----___________________
-- frame_go       _____-___-___-______________




-- When syncing

-- tx_commenc     __--------------------------------
-- frame_sync_qual___-___-___-___-___-___-___-___-__
-- frame_ctr_en   ____------------------------______
-- tx_done        ____________________________------
-- frame_ctr      2222222211110000222211110000222222
-- frame_ctr_is0  ____________----________----______
-- frame_ctr_1st  ____----________----________------
-- sync_ctr_is0   ________________------------______
-- frame_first_pul____-_____________________________
-- frame_first    _________________----_____________
-- frame_go       _________________-___-___-________

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

    framer_rst    : in std_logic;
    tx_always     : in std_logic;
    tx_indefinite : in std_logic;
    tx_commence   : in std_logic; -- once hi stays hi till teardown
    alice_syncing : in std_logic;
    frame_sync_qual: in std_logic; -- request transission by pulsing high for one cycle

    frame_qty_min1 : in std_logic_vector(FRAME_QTY_W-1 downto 0);

    -- control signals indicate when to transmit
    frame_first     : out std_logic;
    frame_first_pul : out std_logic;
    frame_go        : out std_logic); -- pulse at beginning of headers
end frame_ctl;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
architecture rtl of frame_ctl is
  signal pd_ctr_atlim, frame_last, frame_ctr_is0, frame_ctr_is0_d,
    tx_pend, frame_ctr_en, frame_ctr_en_d, frame_first_i, init,
    frame_ctr_1st,
    frame_sync_qual_d,  frame_ctr_stop,  sync_ctr_is0, tx_done: std_logic := '0';
  signal pd_ctr: std_logic_vector(FRAME_PD_CYCS_W-1 downto 0) := (others=>'0');
  signal frame_ctr: std_logic_vector(FRAME_QTY_W-1 downto 0) := (others=>'0');
  signal sync_ctr: std_logic_vector(0 downto 0) := (others=>'0');
begin

  pd_tic <= pd_ctr_atlim;


  frame_ctr_stop <= frame_ctr_is0 and (not alice_syncing or sync_ctr_is0);
  
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

      if (framer_rst='1') then -- probably dont need. for dbg.
        frame_ctr_en <= '0';
      elsif (frame_sync_qual='1') then
        frame_ctr_en <= tx_commence and (tx_indefinite or not (frame_ctr_stop or tx_done));
      end if;
      
      tx_done <= not tx_indefinite and not tx_always and tx_commence and not framer_rst
                 and ((frame_ctr_en and frame_sync_qual and frame_ctr_stop) or tx_done);
      
      -- transmit a certain number of frames per cell
      if ((not frame_ctr_en or (frame_sync_qual and frame_ctr_is0))='1') then
        frame_ctr     <= frame_qty_min1;
        frame_ctr_is0 <= '0';
        frame_ctr_1st <= '1';
      elsif (frame_sync_qual='1') then
        frame_ctr     <= u_dec(frame_ctr);
        frame_ctr_is0 <= u_b2b(unsigned(frame_ctr)=1);
        frame_ctr_1st <= '0';
      end if;
      -- Since frames are always longer than 1 cycle, it works.

      if ((not frame_ctr_en or (frame_sync_qual and frame_ctr_is0 and sync_ctr_is0))='1') then
        sync_ctr     <= "1";
        sync_ctr_is0 <= '0';
      elsif ((alice_syncing and frame_sync_qual and frame_ctr_is0)='1') then
        sync_ctr     <= u_dec(sync_ctr);
        sync_ctr_is0 <= '1';
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



      frame_sync_qual_d <= frame_sync_qual;
      
      -- to trigger saving in quanet_adc... happens once.
      frame_first_pul <= tx_commence and not frame_ctr_en and not tx_done and frame_sync_qual;

      frame_ctr_en_d <= frame_ctr_en;
      frame_ctr_is0_d <= frame_ctr_is0;
      if (frame_sync_qual_d='1') then
        frame_first_i <= frame_ctr_en and frame_ctr_1st and ((not alice_syncing or sync_ctr_is0)
                                                             or tx_indefinite); 
      end if;

      init <= not (frame_ctr_en or tx_done);
      frame_go        <= frame_sync_qual_d and
                         (tx_always or
                            (frame_ctr_en and (not alice_syncing or sync_ctr_is0)));

    end if;
  end process;
  frame_first     <= frame_first_i;


end architecture rtl;
