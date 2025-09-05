
-- synchronizer
-- essentially a slew-limited delay lock loop.
--
-- ref is a pulse that repeats (or not) at a regular or slightly irregular
-- period, or a period that skips or increases a cycle once in a while.
-- lo_pul is a pulse that repeats at the
-- same period, simultaneously, but more regularly.

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
      resync_pul    : in std_logic; -- next ref forces sync to align exactly.
      pd_cycs_min1  : in std_logic_vector(CYCS_W-1 downto 0); 
      ref           : in std_logic; -- pulses once per pd from some other clock
      sync          : out std_logic; -- pulses simultaneously with ref, hopefully.
      resyncing_clk : out std_logic; -- high while aquiring lock


      -- The following signals in pclk ("processor clk") domain
      pclk           : in std_logic;
      errsum_o     : out std_logic_vector(ERRSUM_W-1 downto 0);
      errsum_ovf_o : out std_logic;
      errsum_q_o   : out std_logic_vector(SYNCQTY_W-1 downto 0);
      saw_ool        : out std_logic;
      clr_saw_ool    : in std_logic;
      lor            : out std_logic; -- loss of reference.  (Not a loss of lock)
      resyncing_pclk : out std_logic; -- high while aquiring lock
      lock           : out std_logic); -- 1 means we are keeping up with ref
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
    resync_pul: in std_logic; -- next ref forces sync to align exactly.
    pd_cycs_min1: in std_logic_vector(CYCS_W-1 downto 0); 
    ref: in std_logic; -- pulses once per pd from some other clock
    sync: out std_logic; -- pulses simultaneously with ref, hopefully.
    resyncing_clk  : out std_logic; -- high while aquiring lock
    

    -- The following signals in pclk ("processor clk") domain
    pclk           : in std_logic;
    errsum_o     : out std_logic_vector(ERRSUM_W-1 downto 0);
    errsum_ovf_o : out std_logic;
    errsum_q_o   : out std_logic_vector(SYNCQTY_W-1 downto 0);
    saw_ool     : out std_logic;
    clr_saw_ool : in std_logic;
    lor         : out std_logic; -- loss of reference.  (Not a loss of lock).
                                 -- no ref after 256 periods (frames)
    resyncing_pclk : out std_logic; -- high while aquiring lock
    lock           : out std_logic); -- 1 means we are keeping up with ref
end synchronizer;
    
library ieee;
use ieee.numeric_std.all;
library work;
use work.util_pkg.all;
use work.cdc_thru_pkg.all;
use work.cdc_pulse_pkg.all;
use work.cdc_samp_pkg.all;
use work.event_mon_pkg.all;
use work.duration_upctr_pkg.all;
architecture rtl of synchronizer is
  signal ctr, half_pd_min1: std_logic_vector(CYCS_W-1 downto 0) := (others=>'0');
  signal ctr_is1, ctr_atlim, inc, dec, hp_go, hp, hp_last, hp_rst,
    ref_first, lo_first, lo_pul, lo_pul_d, resyncing, insert_cyc, delete_cyc,
    lo_ctr_atlim, ool_ctr_atlim, lor_i, ctr_runaway,
    insert_cyc_d, delete_cyc_dd, delete_cyc_2d, delete_cyc_d, lock_i, lock_pd_pul,
    durs_rst: std_logic := '0';
  signal votes: std_logic_vector(VOTES_W-1 downto 0) := (others=>'0');
  signal vote_in, votes_neg, votes_pos, votes_neg_d, votes_almost, votes_clr: std_logic := '0';

  signal ool_ctr: std_logic_vector(VOTES_W-1 downto 0) := (others=>'0');
  signal lor_ctr: std_logic_vector(7 downto 0) := (others=>'0');
  signal hp_ctr:   std_logic_vector(CYCS_W-1 downto 0) := (others=>'0');

  signal errsum, errsum_sav, errsum_proc:   std_logic_vector(ERRSUM_W-1 downto 0) := (others=>'0');
  signal errsum_q, errsum_q_sav, errsum_q_proc, statpd_ctr: std_logic_vector(SYNCQTY_W-1 downto 0) := (others=>'0');
  signal errsum_o_vld, errsum_ovf_sav, errsum_ovf_proc,
    errsum_afull, statpd_atlim, errsum_o_vld_proc: std_logic :='0';

  signal lo_ctr: std_logic_vector(8 downto 0) := (others=>'0');
  
begin
  sync <= lo_pul;

  lock_pd_pul   <= lo_pul and lo_ctr_atlim;
  resyncing_clk <= resyncing;

  process(clk)
  begin
    if (rising_edge(clk)) then
      half_pd_min1 <= u_dec('0'&pd_cycs_min1(CYCS_W-1 downto 1));
      resyncing <= (resync_pul or resyncing) and not ref;
      ctr_runaway <= u_b2b(unsigned(ctr) > unsigned(pd_cycs_min1));
      if ((resyncing or lo_pul or ctr_runaway)='1') then
        ctr     <= pd_cycs_min1;
        lo_pul  <= '0';
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
        -- This is like a local oscillator in a PLL
        lo_pul <=    (u_b2b(unsigned(ctr)=1) and not insert_cyc)
                  or (u_b2b(unsigned(ctr)=2) and delete_cyc);
        ctr_is1 <= u_b2b(unsigned(ctr)=2)
                   and not insert_cyc and not delete_cyc; -- not always true but OK
      end if;

      ref_first  <= ((ref    and not hp) or ref_first) and not (lo_pul or hp_last or resyncing);
      lo_first   <= ((lo_pul and not hp) or lo_first)  and not (ref    or hp_last);
      lo_pul_d <= lo_pul;

      if ((resyncing or (lo_pul_d and statpd_atlim))='1') then
        errsum       <= (others=>'0');
        errsum_q     <= (others=>'0');
        errsum_afull <= '0';
        errsum_sav     <= errsum;
        errsum_q_sav   <= errsum_q;
        errsum_ovf_sav <= errsum_afull and not errsum(ERRSUM_W-1);
      elsif (((ref_first and lo_pul) or (lo_first and ref))='1') then
        errsum       <= u_add_u(errsum, hp_ctr);
        errsum_afull <= errsum_afull or errsum(ERRSUM_W-1);
        errsum_q     <= u_inc(errsum_q);
      elsif ((ref and lo_pul)='1') then
        errsum_q     <= u_inc(errsum_q);
      end if;
      errsum_o_vld <= lo_pul_d and statpd_atlim;
      
      if ((resyncing or (lo_pul_d and statpd_atlim)) = '1') then
        -- we leave a little room because errsum_q could be just as big.
        statpd_ctr <= u_rpt('1',SYNCQTY_W-2)&"00";
      elsif (lo_pul_d='1') then
        statpd_ctr <= u_dec(statpd_ctr);
      end if;
      statpd_atlim <= u_b2b(unsigned(statpd_ctr)=0);
      
      if ((resyncing or votes_clr)='1') then
        votes <= (others=>'0');
      elsif (((ref_first and lo_pul) or (ref and lo_pul and votes_pos))='1') then
        votes <= u_dec(votes); -- vote to delete a cycle
      elsif (((lo_first and   ref) or (ref and lo_pul and votes_neg))='1') then
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
      insert_cyc_d <= insert_cyc and lo_pul;
      delete_cyc_d <= delete_cyc and lo_pul;
      -- if del happens when ctr=1, actually del two cycs later
      delete_cyc_2d <= delete_cyc and ctr_is1;
      delete_cyc_dd <= delete_cyc_2d;

      -- Too many adjustments (ins or del cyc) within some period (lock pd)
      -- is considered a loss of lock situation.
      -- TODO: consider the regaining of the lock.  Is it possible, or trustworthy?
      if ((   (ref and resyncing)
           or (lock_pd_pul and not ool_ctr_atlim))='1') then 
        ool_ctr <= (others=>'0');
        lock_i  <= '1';
      elsif ((   resyncing
              or (lock_pd_pul and ool_ctr_atlim))='1') then
        lock_i  <= '0';
      elsif ((insert_cyc or delete_cyc)='1') then
        if (ool_ctr_atlim='1') then
          lock_i <= '0';
        else
          ool_ctr <= u_inc(ool_ctr);
        end if;
      end if;
      ool_ctr_atlim <= u_and(ool_ctr);

      -- This counts periods (frames)
      if ((resyncing or (lo_pul and lo_ctr_atlim))='1') then
        lo_ctr <= (others=>'1');
      elsif (lo_pul='1') then
        lo_ctr <= u_inc(lo_ctr);
      end if;
      lo_ctr_atlim <= u_b2b(unsigned(lo_ctr)=0);


      -- Loss of ref
      if ((   (ref and (lo_pul or resyncing))
              or (lo_first and ref and votes_neg)
              or (ref_first and lo_pul and votes_pos))='1') then
        lor_ctr <= (others=>'0');
        lor_i   <= '0';
      elsif ((resyncing or lo_pul)='1') then
        if (u_and(lor_ctr)='1') then
          lor_i <= '1';
        else
          lor_i <= '0';
          lor_ctr <= u_inc(lor_ctr);
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
      out_clk   => pclk);
  
  lor_samp: cdc_samp
    generic map(W=>1)
    port map(
      in_data(0)  => lor_i,
      out_data(0) => lor,
      out_clk     => pclk);
  
  hp_go   <= (ref xor lo_pul) and not hp and not resyncing;
  vote_in <= (ref or lo_pul) and     hp and not resyncing;
  hp_rst <= resyncing or (hp and (ref or lo_pul));
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
      
      procclk       => pclk,
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


  
  process(pclk)
  begin
    if (rising_edge(pclk)) then
      if (errsum_o_vld_proc='1') then
        errsum_o     <= errsum_proc;
        errsum_ovf_o <= errsum_ovf_proc;
        errsum_q_o   <= errsum_q_proc;
      end if;
    end if;
  end process;
  
end architecture rtl;
