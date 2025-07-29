
-- synchronizer
-- essentially a slew-limited delay lock loop.
--
-- ref is a pulse that repeats at a regular period based
-- on one (remote) clock, and sync is a pulse that repeats at the
-- same period but based on another (local) clock.

-- When "locked", the phase may change no faster than one cycle
-- per pd_cycs*(2^VOTES_W)/2 cycles. This means the max
-- ratio between ref's originating clock and the local
-- clock must be < 1/(pd_cycs*(2^VOTES_W)/2).
--
-- For example: a 1us frame period (1000 cycs) and VOTES_W=4,
-- fastest change possible would be 1/(1000*8),
-- which could easily keep up with a 1ppm difference in 1GHz clocks.

-- Don't feed pulses into the ref input when they might be garbage.
-- For example, qualify that signal with other relevant conditions
-- such as pll lock, RSS or ~LOS.

-- If we continually try to increase or decrease the phase in the same
-- direction every period, we're probably out of lock.  But if sometimes the ref and sync
-- coincide, or if we vote to change direction, we must be keeping up.
-- So we require or coincidence or one change within every N periods 
-- to assert lock.  Where N = (2^VOTES_W)/2.


library ieee;
use ieee.std_logic_1164.all;
package synchronizer_pkg is
  component synchronizer
    generic (
      CYCS_W: integer;
      VOTES_W: integer;
    ERRSUM_W: integer;
    SYNCQTY_W: integer);
    port (
      clk: in std_logic;
      rst: in std_logic;
      resync: in std_logic; -- next ref forces sync to align exactly.
      pd_cycs_min1: in std_logic_vector(CYCS_W-1 downto 0); 
      ref: in std_logic; -- pulses once per pd from some other clock
      sync: out std_logic; -- pulses simultaneously with ref, hopefully.

      errsum_o     : out std_logic_vector(ERRSUM_W-1 downto 0);
      errsum_ovf_o : out std_logic;
      errsum_q_o   : out std_logic_vector(SYNCQTY_W-1 downto 0);
    
    procclk     : in std_logic;
    saw_ool     : out std_logic;
    clr_saw_ool : in std_logic;
    lock        : out std_logic); -- 1 means we are keeping up with ref
  end component;
  
end synchronizer_pkg;  

library ieee;
use ieee.std_logic_1164.all;
entity synchronizer is
  generic (
    CYCS_W: integer;
    VOTES_W: integer;
    ERRSUM_W: integer;
    SYNCQTY_W: integer);
  port (
    clk: in std_logic;
    rst: in std_logic;
    resync: in std_logic; -- next ref forces sync to align exactly.
    pd_cycs_min1: in std_logic_vector(CYCS_W-1 downto 0); 
    ref: in std_logic; -- pulses once per pd from some other clock
    sync: out std_logic; -- pulses simultaneously with ref, hopefully.

    errsum_o     : out std_logic_vector(ERRSUM_W-1 downto 0);
    errsum_ovf_o : out std_logic;
    errsum_q_o   : out std_logic_vector(SYNCQTY_W-1 downto 0);
    
    procclk     : in std_logic;
    saw_ool     : out std_logic;
    clr_saw_ool : in std_logic;
    lock        : out std_logic); -- 1 means we are keeping up with ref
end synchronizer;
    
library ieee;
use ieee.numeric_std.all;
library work;
use work.global_pkg.all;
use work.util_pkg.all;
use work.cdc_thru_pkg.all;
use work.cdc_pulse_pkg.all;
use work.event_mon_pkg.all;
use work.duration_upctr_pkg.all;
architecture rtl of synchronizer is
  signal ctr, half_pd_min1: std_logic_vector(CYCS_W-1 downto 0) := (others=>'0');
  signal ctr_is1, ctr_atlim, inc, dec, hp_go, hp, hp_last, hp_rst,
    ref_first, sync_first, sync_i, sync_d,resyncing, insert_cyc, delete_cyc,
    insert_cyc_d, delete_cyc_dd, delete_cyc_2d, delete_cyc_d, lock_i,
    durs_rst: std_logic := '0';
  signal votes: std_logic_vector(VOTES_W-1 downto 0) := (others=>'0');
  signal vote_in, votes_neg, votes_pos, votes_neg_d, votes_almost, votes_clr: std_logic := '0';

  signal ool_ctr: std_logic_vector(VOTES_W-1 downto 0) := (others=>'0');
  signal hp_ctr:   std_logic_vector(CYCS_W-1 downto 0) := (others=>'0');

  signal errsum, errsum_sav, errsum_proc:   std_logic_vector(ERRSUM_W-1 downto 0) := (others=>'0');
  signal errsum_q, errsum_q_sav, errsum_q_proc, statpd_ctr: std_logic_vector(SYNCQTY_W-1 downto 0) := (others=>'0');
  signal errsum_o_vld, errsum_ovf_sav, errsum_ovf_proc,
    errsum_afull, statpd_atlim, errsum_o_vld_proc: std_logic :='0';
  
begin
  sync <= sync_i;
  process(clk)
  begin
    if (rising_edge(clk)) then
      half_pd_min1 <= u_dec('0'&pd_cycs_min1(CYCS_W-1 downto 1));
      resyncing <= (resync or resyncing) and not ref;
      if ((resyncing or sync_i)='1') then
        ctr     <= pd_cycs_min1;
        sync_i  <= '0';
        ctr_is1 <= '0';
      else
        if ((    (delete_cyc and not ctr_is1) or delete_cyc_d or delete_cyc_dd
               or insert_cyc or insert_cyc_d)='1') then
          if ((delete_cyc or delete_cyc_d or delete_cyc_dd)='1') then
            ctr <= u_sub_u(ctr,"10");
          end if;
        else
          ctr   <= u_dec(ctr);
        end if;
        sync_i <=    (u_b2b(unsigned(ctr)=1) and not insert_cyc)
                  or (u_b2b(unsigned(ctr)=2) and delete_cyc);
        ctr_is1 <= u_b2b(unsigned(ctr)=2)
                   and not insert_cyc and not delete_cyc; -- not always true but OK
      end if;

      ref_first  <= ((ref    and not hp) or ref_first) and not (sync_i or hp_last);
      sync_first <= ((sync_i and not hp) or sync_first) and not (ref or hp_last);
      sync_d <= sync_i;

      if ((resyncing or (sync_d and statpd_atlim))='1') then
        errsum       <= (others=>'0');
        errsum_q     <= (others=>'0');
        errsum_afull <= '0';
        errsum_sav     <= errsum;
        errsum_q_sav   <= errsum_q;
        errsum_ovf_sav <= errsum_afull and not errsum(ERRSUM_W-1);
      elsif (((ref_first and sync_i) or (sync_first and ref))='1') then
        errsum       <= u_add_u(errsum, hp_ctr);
        errsum_afull <= errsum_afull or errsum(ERRSUM_W-1);
        errsum_q     <= u_inc(errsum_q);
      elsif ((ref and sync_i)='1') then
        errsum_q     <= u_inc(errsum_q);
      end if;
      errsum_o_vld <= sync_d and statpd_atlim;
      
      if ((resyncing or (sync_d and statpd_atlim)) = '1') then
        -- we leave a little room because errsum_q could be just as big.
        statpd_ctr <= u_rpt('1',SYNCQTY_W-2)&"00";
      elsif (sync_d='1') then
        statpd_ctr <= u_dec(statpd_ctr);
      end if;
      statpd_atlim <= u_b2b(unsigned(statpd_ctr)=0);
      
      if ((resyncing or votes_clr)='1') then
        votes <= (others=>'0');
      elsif (((ref_first and sync_i) or (ref and sync_i and votes_pos))='1') then
        votes <= u_dec(votes); -- vote to delete a cycle
      elsif (((sync_first and   ref) or (ref and sync_i and votes_neg))='1') then
        votes <= u_inc(votes); -- vote to insert a cycle
      end if;
      votes_neg_d  <= votes_neg;
      votes_almost <= (votes_neg xor votes(VOTES_W-2)) and vote_in;
      votes_clr    <= votes_almost and (    votes_neg_d xor     votes_neg);
      insert_cyc   <= votes_almost and (not votes_neg_d and     votes_neg);
      delete_cyc   <= votes_almost and (    votes_neg_d and not votes_neg);

      -- The following covers situations highly unlikely,
      -- but the resources to add these checks are very low.
      -- 
      -- if ins or del simultaneous with sync, ctr<=pd-1 takes precidence.
      -- so in that case we delay the ins or del.
      insert_cyc_d <= insert_cyc and sync_i;
      delete_cyc_d <= delete_cyc and sync_i;
      -- if del happens when ctr=1, actually del two cycs later
      delete_cyc_2d <= delete_cyc and ctr_is1;
      delete_cyc_dd <= delete_cyc_2d;

      if ((   (ref and sync_i)
              or (sync_first and ref and votes_neg)
              or (ref_first and sync_i and votes_pos))='1') then
        ool_ctr <= (others=>'0');
        lock_i    <= '1';
      elsif ((resyncing or sync_i)='1') then
        if (u_and(ool_ctr)='1') then
          lock_i <= '0';
        else
          ool_ctr <= u_inc(ool_ctr);
        end if;
      end if;

    end if;
  end process;
  votes_neg <= votes(VOTES_W-1);
  votes_pos <= not votes(VOTES_W-1) and u_or(votes(VOTES_W-2 downto 0));

  vld_pul: cdc_pulse
    port map(
      in_pulse  => errsum_o_vld,
      in_clk    => clk,
      out_pulse => errsum_o_vld_proc,
      out_clk   => procclk);
  
  hp_go   <= (ref xor sync_i) and not hp;
  vote_in <= (ref or sync_i) and     hp;
  hp_rst <= hp and (ref or sync_i);
  ref_dur_ctr: duration_upctr
    generic map(
      LEN_W => CYCS_W)
    port map(
      clk      => clk,
      rst      => hp_rst,
      go_pul   => hp_go,
      ctr_o    => hp_ctr,
      len_min1 => half_pd_min1,
      sig_o    => hp,
      sig_last => hp_last);

  lock_mon: event_mon
    port map(
      event      => lock_i,
      event_clk  => clk,
      
      procclk       => procclk,
      event_out     => lock,
      saw_not_event => saw_ool,
      clr           => clr_saw_ool);
  
  stats_ovf_thru: cdc_thru
    generic map(W=>1)
    port map(
      in_data(0)   => errsum_ovf_sav,
      out_data(0)  => errsum_ovf_proc);
  ersp_stats_thru: cdc_thru
    generic map(W=>ERRSUM_W)
    port map(
      in_data => errsum_sav,
      out_data => errsum_proc);
  stats_q_thru: cdc_thru
    generic map(W=>SYNCQTY_W )
    port map(
      in_data => errsum_q_sav,
      out_data => errsum_q_proc);


  
  process(procclk)
  begin
    if (rising_edge(procclk)) then
      if (errsum_o_vld_proc='1') then
        errsum_o     <= errsum_proc;
        errsum_ovf_o <= errsum_ovf_proc;
        errsum_q_o   <= errsum_q_proc;
      end if;
    end if;
  end process;
  
end architecture rtl;
