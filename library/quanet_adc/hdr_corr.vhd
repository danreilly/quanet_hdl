

-- For reflection monitoring, we are typically looking at small siganls.
-- So we discard the MSBs of the ADC samples.  This is called the
-- "reduced sample width".


-- If the hdr pd is not an even multiple of the header len,
-- there will be a little garbage at the end of correlation.
-- But we can avoid that.

library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
package hdr_corr_pkg is
  
  component hdr_corr is
  generic (
    USE_CORR: integer;
    SAMP_W : integer; -- 12 - width of one sample from one ADC.
    FRAME_PD_CYCS_W: integer; -- 24
    REDUCED_SAMP_W: integer; -- 8 -- after discarding MSBs
    HDR_LEN_CYCS_W: integer; -- 32
    MAX_SLICES: integer;
    PASS_W: integer;
    FRAME_QTY_W: integer; -- 16
    MEM_D_W: integer;
    MAG_W: integer); -- number of bits used to store a correlation value
  port (
    clk           : in std_logic;
    rst           : in std_logic;
    osamp_min1    : in std_logic_vector(1 downto 0);
    corrstart_in  : in std_logic;
    
    search         : in std_logic;
    search_restart : in std_logic;
    dbg_hold : in std_logic;
    dbg_framer_going : out std_logic;
    alice_syncing : in std_logic;
    alice_txing   : in std_logic;
    frame_pd_min1 : in std_logic_vector(FRAME_PD_CYCS_W-1 downto 0);
--    num_pass_min1 : in std_logic_vector(u_bitwid((2**HDR_LEN_CYCS_W+MAX_SLICES-1)/MAX_SLICES-1)-1 downto 0);
    num_pass_min1 : in std_logic_vector(PASS_W-1 downto 0);
    hdr_len_min1_cycs : in std_logic_vector(HDR_LEN_CYCS_W-1 downto 0);
    frame_qty_min1 : in std_logic_vector(FRAME_QTY_W-1 downto 0);
    init_thresh_d16 : in std_logic_vector(7 downto 0); -- compared with power    
    hdr_pwr_thresh : in std_logic_vector(SAMP_W-1 downto 0); -- compared with power    
    hdr_thresh     : in std_logic_vector(MAG_W-1 downto 0);
    lfsr_rst_st    : in std_logic_vector(10 downto 0);    

    samps_in  : in std_logic_vector(SAMP_W*8-1 downto 0);

    -- Once a header has been detected, this pulses periodically
    -- at the header period.  To be used in QSDC for payload insertion.
    dbg_pwr_event_iso : out std_logic; -- means sufficient power was detected
    hdr_pwr_det    : out std_logic; -- means sufficient power was detected
    dbg_hdr_det     : out std_logic; -- will preceed hdr sync
    met_init_o      : out std_logic;
    hdr_subcyc      : out std_logic_vector(1 downto 0);
    hdr_sync        : out std_logic;
    hdr_found_out   : out std_logic;
    sync_dly        : in std_logic_vector(FRAME_PD_CYCS_W-1 downto 0);
    hdr_sync_dlyd   : out std_logic;
    
    -- If this is computing correlations for CDM (lidar),
    -- the correlation values come out these ports:
    corr_vld: out std_logic;
    corr_out: out std_logic_vector(MEM_D_W*4-1 downto 0);

    -- Rather than convey each statistic up out through its own named port,
    -- they are indexed.  The processor reads them by first setting proc_sel,
    -- then reading proc_dout.
    proc_clk      : in std_logic;
    proc_clr_cnts : in std_logic;
    proc_sel      : in std_logic_vector(3 downto 0);
    proc_dout     : out std_logic_vector(31 downto 0));

  
  end component;

end package;
  
library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
entity hdr_corr is
  generic (
    USE_CORR: integer;
    SAMP_W : integer; -- 12 - width of one sample from one ADC.
    REDUCED_SAMP_W: integer; -- 8 -- after discarding MSBs
    HDR_LEN_CYCS_W: integer; -- 32
    MAX_SLICES: integer;
    PASS_W: integer;
    FRAME_PD_CYCS_W: integer; -- 32
    FRAME_QTY_W: integer;
    MEM_D_W: integer;
    MAG_W: integer); -- 10
  port (
    clk          : in std_logic;
    rst          : in std_logic;
    osamp_min1   : in std_logic_vector(1 downto 0);
    corrstart_in : in std_logic;

    -- ctl and status
    search         : in std_logic;
    search_restart : in std_logic;
    dbg_hold : in std_logic;
    dbg_framer_going : out std_logic;
    alice_syncing  : in std_logic;
    alice_txing   : in std_logic;
    frame_pd_min1  : in std_logic_vector(FRAME_PD_CYCS_W-1 downto 0);
--    num_pass_min1  : in std_logic_vector(u_bitwid((2**HDR_LEN_CYCS_W+MAX_SLICES-1)/MAX_SLICES-1)-1 downto 0);
    num_pass_min1: in std_logic_vector(PASS_W-1 downto 0);
    frame_qty_min1 : in std_logic_vector(FRAME_QTY_W-1 downto 0); -- really a period qty
    hdr_len_min1_cycs  : in std_logic_vector(HDR_LEN_CYCS_W-1 downto 0);
    init_thresh_d16 : in std_logic_vector(7 downto 0); -- compared with power    
    hdr_pwr_thresh : in std_logic_vector(SAMP_W-1 downto 0); -- compared with power    
    hdr_thresh     : in std_logic_vector(MAG_W-1 downto 0);
    lfsr_rst_st    : in std_logic_vector(10 downto 0);    

    samps_in  : in std_logic_vector(SAMP_W*8-1 downto 0);

    -- Once a header has been detected, this pulses periodically
    -- at the header period.  To be used in QSDC for payload insertion.
    dbg_pwr_event_iso : out std_logic; -- means sufficient power was detected
    hdr_pwr_det: out std_logic; -- will preceed hdr det
    dbg_hdr_det     : out std_logic; -- will preceed hdr sync
    met_init_o      : out std_logic;
    hdr_subcyc      : out std_logic_vector(1 downto 0);
    hdr_sync        : out std_logic;
    hdr_found_out   : out std_logic;
    sync_dly        : in std_logic_vector(FRAME_PD_CYCS_W-1 downto 0); 
    hdr_sync_dlyd   : out std_logic;
   
    -- If this is computing correlations for CDM (lidar),
    -- the correlation values come out these ports:
    corr_vld: out std_logic;
    corr_out: out std_logic_vector(MEM_D_W*4-1 downto 0);

    -- Rather than convey each statistic up out through its own named port,
    -- they are indexed.  The processor reads them by first setting proc_sel,
    -- then reading proc_dout.
    proc_clk: in std_logic;
    proc_clr_cnts : in std_logic;
    proc_sel: in std_logic_vector(3 downto 0);
    proc_dout: out std_logic_vector(31 downto 0));
  
end hdr_corr;

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.util_pkg.all;
use work.cdc_samp_pkg.all;
use work.cdc_pulse_pkg.all;
use work.global_pkg.all;
use work.gen_hdr_pkg.all;
use work.uram_infer_pkg.all;
use work.period_timer_pkg.all;
use work.event_ctr_pkg.all;
use work.event_ctr_periodic_pkg.all;
use work.timekeeper_pkg.all;
architecture struct of hdr_corr is


  -- IS THIS TRUE: ????
  -- Vivado was trying to automatically infer an interface called "hdr".
--  ATTRIBUTE X_INTERFACE_IGNORE:STRING;
--  ATTRIBUTE X_INTERFACE_IGNORE OF hdr_sync, hdr_subcyc: SIGNAL IS "TRUE";
  
  -- The power-based header detection operates on undelayed samples.
  -- It may take a few cycles to raise a flag to start the correlators.
  -- So samples to correlators are delayed this many cycles, so one of
  -- them will hopefully see the start of the header.
  --
  -- This delay value found in simulation on actual data.
  constant SAMP_DLY: integer := 4;
  
  component hdr_corr_slice
    generic (
      SAMP_W : integer; -- 12 - width of one sample from one ADC.
      HDR_LEN_CYCS_W: integer;
      MAG_W : integer;
      SUM_SHFT_W: integer);     
    port (
      clk       : in std_logic;
      hdr_in    : in std_logic_vector(3 downto 0);
      start_in  : in std_logic;
      hdr_end_pul: in std_logic;
      
      
      samps_d0  : in std_logic_vector(SAMP_W*8-1 downto 0);
      samps_d1  : in std_logic_vector(SAMP_W*8-1 downto 0);
      samps_d2  : in std_logic_vector(SAMP_W*8-1 downto 0);
      samps_d3  : in std_logic_vector(SAMP_W*8-1 downto 0);

      sum_shft  : in std_logic_vector(SUM_SHFT_W-1 downto 0); -- ceil(log2(hdr_len-1))
      hdr_out   : out std_logic_vector(3 downto 0);
      corr_i_out   : out std_logic_vector(MAG_W*4-1 downto 0);
      corr_q_out   : out std_logic_vector(MAG_W*4-1 downto 0));
  end component;

  component pwr_det
    generic (
      PD_CYCS: integer;      
      MSK_LEN_W: integer;
      SAMP_W : integer); -- 12 - width of one sample from one ADC.
    port (
      clk            : in std_logic;
      samps_in       : in std_logic_vector(SAMP_W*8-1 downto 0);
      hdr_pwr_thresh : in std_logic_vector(SAMP_W-1 downto 0);
      msk_len_min1_cycs : in std_logic_vector(MSK_LEN_W-1 downto 0);
      pwr_avg        : out std_logic_vector(SAMP_W-1 downto 0); -- over pd
      pwr_avg_max    : out std_logic_vector(SAMP_W-1 downto 0); -- over pd
      pwr_event      : out std_logic;
      pwr_event_iso  : out std_logic; -- "isolated" power event.
      clr_max        :  in std_logic);
  end component;

  constant SLICE_IDX_W: integer := u_bitwid(MAX_SLICES-1);
--  constant PASS_W: integer := u_bitwid((2**HDR_LEN_CYCS_W+MAX_SLICES-1)/MAX_SLICES-1);
  signal pass_ctr: std_logic_vector(PASS_W-1 downto 0) := (others=>'0');
  signal pass_ctr_atlim: std_logic:='0';
  -- Each "pass" through a "period", we start correlations at a "pass offset"
  -- (in cycles)
  signal pass_offset: std_logic_vector(PASS_W+u_bitwid(MAX_SLICES-1)-1 downto 0):= (others=>'0');

  -- we correlate frame_qty full periods
  signal pd_ctr: std_logic_vector(FRAME_QTY_W-1 downto 0);
  signal hdr_sync_i, hdr_dly_en, passpd_first, passpd_sav, passpd_sec, pd_ctr_atlim, use_mem_dout: std_logic := '0';
  
  signal allpass_done, allpass_pend: std_logic:='0';
  constant NUM_SLICES: integer := u_min(MAX_SLICES, 2**HDR_LEN_CYCS_W);
  signal slice_go, slice_done, allpass_done_p, slice_done_p, allpass_end_p: std_logic_vector(NUM_SLICES-1 downto 0) := (others=>'0');
  signal allpass_dly_p: std_logic_vector(4 downto 0) := (others=>'0');


  signal last_slice_min1, last_slice_min2, rshift_ctr, rshift_ctr_d: std_logic_vector(SLICE_IDX_W-1 downto 0) := (others=>'0');
  signal cshift_ctr: std_logic_vector(1 downto 0) := "00";
  signal rshift_shft, rshift_ctr_atlim, cshift_ctr_atlim: std_logic;
  
  type samp_a_t is array(0 to 7) of std_logic_vector(SAMP_W-1 downto 0);
  signal samp_a: samp_a_t;
  -- The samples are reduced by some sort of AGC mechanism (not made yet)  
  type sampred_a_t is array(0 to 7) of std_logic_vector(REDUCED_SAMP_W-1 downto 0);
  signal sampred_a: sampred_a_t;
  -- Then delayed so pwr-based detector has time to work.
  type sampreddly_a_t is array(0 to SAMP_DLY-1) of std_logic_vector(8*REDUCED_SAMP_W-1 downto 0);
  signal sampreddly_a: sampreddly_a_t :=(others=>(others=>'0')); 
  
  signal samps_red, samps_red_pre, samps_red_d0, samps_red_d1, samps_red_d2, samps_red_d3: std_logic_vector(8*REDUCED_SAMP_W-1 downto 0);
  signal dbg_samps_red, dbg_samps_red_pre: std_logic_vector(REDUCED_SAMP_W-1 downto 0);
  signal pwr_avg, pwr_avg_max: std_logic_vector(SAMP_W-1 downto 0);

  type hdr_a_t is array(0 to NUM_SLICES) of std_logic_vector(3 downto 0);
  signal hdr_a: hdr_a_t := (others=>(others=>'0'));

  type mags_a_t is array(0 to NUM_SLICES-1) of std_logic_vector(MAG_W*4-1 downto 0);
  signal slice_corr_i_a, slice_corr_q_a,
         shreg_i_a, shreg_q_a: mags_a_t := (others=>(others=>'0'));
  -- each element of array contains four correlation magnitudes

  type cmags_a_t is array(0 to 3) of std_logic_vector(MAG_W-1 downto 0);
  signal cshift_i_a, cshift_q_a: cmags_a_t;
  signal cshift_mag, maxsofar_mag, maxsofar_i, maxsofar_q,
    best_mag,
    hdr_i, hdr_q, hdr_mag, hdr_mag_proc: std_logic_vector(MAG_W-1 downto 0);
  
  signal shreg_vld, shreg_vld_d,
    mem_din_vld, qcorr_done, lst_vld, lst_vld_last_pass, lst_vld_d, lst_vld_dd, corr_starts_hdr, maxsofar_vld, maxsofar_vld_d,  proc_clr_cnts_adc,
    gen_hdr_go, gen_hdr_go_d, hdr_det_changed, new_best, hdr_det_cnt_clr,
    hdr_found, hdr_found_pclk, hdr_found_d, hdr_found_dd, hdr_found_ddd,
    hdr_det, hdr_det_d, hdr_det_dd, hdr_det_ddd: std_logic := '0';
  signal gen_hdr_out: std_logic_vector(3 downto 0) := "0000";
  signal mags_out_first_i, mags_out_vld, hdr_vld, hdr_end_pre, hdr_end_pul,
    allpass_end, allpass_end_pre,
    hdr_end_d: std_logic := '0';  
--  signal rr_q: std_logic_vector(MAG_W*4-1 downto 0) := (others=>'0');

  
  
  signal hdr_subcyc_i, maxsofar_subcyc: std_logic_vector(1 downto 0) := (others=>'0');
  signal hdr_cyc, hdr_cyc_first, slice_0_cyc,
    frame_cyc, mem_cyc_ctr: std_logic_vector(FRAME_PD_CYCS_W-1 downto 0) := (others=>'0');
  signal hdr_cyc_w, hdr_cyc_pre, frame_pd: std_logic_vector(FRAME_PD_CYCS_W downto 0) := (others=>'0');



  type mag_a_t is array(3 downto 0) of std_logic_vector(MAG_W-1 downto 0);
  type cyc_a_t is array(3 downto 0) of std_logic_vector(FRAME_PD_CYCS_W-1 downto 0);  
  signal mag_out_a, mag_max_a, mag_out_a_d, mag_or_a, max_shreg_a: mag_a_t := (others=>(others=>'0'));
--  signal mag_max_new: std_logic_vector(3 downto 0) := "0000";
--  signal max_max_pulse, mag_max_shift, mag_max_pre_vld, mag_max_gt_thresh: std_logic:='0';
--  signal mag_max_shift_ctr: std_logic_vector(1 downto 0) := "00";  
--  signal mag_max, mag_max_proc: std_logic_vector(MAG_W-1 downto 0);
--  signal mag_max_cyc_a: cyc_a_t;
  signal maxsofar_row, hdr_det_row: std_logic_vector(SLICE_IDX_W-1 downto 0);
  signal hdr_cyc_rel: std_logic_vector(SLICE_IDX_W+1 downto 0);
  signal mag_max_cyc_proc, mag_max_cyc: std_logic_vector(FRAME_PD_CYCS_W-1 downto 0);
--  signal mag_max_ph: std_logic_vector(1 downto 0);

  
  
  signal max_max_vld: std_logic:='0';
  signal find_max_ctr: std_logic_vector(1 downto 0);
  signal find_max_en: std_logic;

  signal corr_go, corrstart_d,
    corr_start,
    framer_going, pd_first, pd_start_pul, framer_last, frame_end_pul,
    frame_end_pul_pre, pd_started, a_going, going, going_d, mags_vld_pre,
    framer_go, framer_go_4search: std_logic := '0';

  signal a_sync_ctr: std_logic_vector(1 downto 0);
  signal a_sync_ctr_atlim: std_logic;
  
  signal frame_pd_min2 : std_logic_vector(FRAME_PD_CYCS_W-1 downto 0);
  
  constant MEM_A_W : integer := u_max(12, FRAME_PD_CYCS_W);
--  constant MEM_D_W : integer := MAG_W+4; -- could be wider, even.
  constant MEM_W   : integer := u_max(72, MEM_D_W*4); -- four data words per entry
  
  signal mem_waddr_inc, mem_rd, pd_sec, mem_raddr_atlim, 
    mem_firstpass, mem_waddr_atlim, mem_waddr_atlim_pre,
    hdr_restart, corr_vld_i: std_logic:='0';
  signal hdr_restart_ctr, raddr_inc_cyc: std_logic_vector(HDR_LEN_CYCS_W-1 downto 0);
  signal pd_sec_dly: std_logic_vector(4 downto 0) := (others=>'0');
  signal mem_din, mem_dout: std_logic_vector(MEM_W-1 downto 0);
  signal mem_waddr, mem_raddr: std_logic_vector(MEM_A_W-1 downto 0) := (others=>'0');
  type mem_data_a_t is array(0 to 3) of std_logic_vector(MEM_D_W-1 downto 0);
  signal mem_din_a, mem_dout_a, mag_add_a, corr_sum_a, corr_dout_a: mem_data_a_t;

  signal lfsr_state_in, lfsr_state_nxt, lfsr_state_sav: std_logic_vector(10 downto 0) := (others=>'0');
  signal lfsr_state_nxt_vld, pwr_event_pre, pwr_event_iso, rst_d, rst_pulse, met_init_d, met_init_pulse,
    hdr_pwr_det_i, hdr_pwr_det_d, hdr_pwr_event, met_init, init_event,
    pwr_search_go, search_go, pwr_searching, searching, search_d, search_pulse: std_logic :='0';

  constant SUM_SHFT_W: integer := u_bitwid(HDR_LEN_CYCS_W-1);
  signal sum_shft: std_logic_vector(SUM_SHFT_W-1 downto 0);

  constant NUM_PROC_DOUTS: integer := 16;
  type proc_dout_a_t is array(0 to NUM_PROC_DOUTS-1) of std_logic_vector(31 downto 0);
  signal proc_dout_pre_a, proc_dout_a: proc_dout_a_t := (others=>(others=>'0'));
  signal proc_dout_pre0: std_logic_vector(31 downto 0);

  constant CTR_W: integer := 16; -- FRAME_QTY_W;
  constant EVENTS_QTY: integer := 3;
  signal   event_v: std_logic_vector(EVENTS_QTY-1 downto 0);
  type event_cnt_a_t is array(0 to EVENTS_QTY-1) of std_logic_vector(CTR_W-1 downto 0);  
  signal event_cnt_a: event_cnt_a_t;
  
  signal hdr_pwr_cnt, hdr_det_cnt, search_cnt, rst_cnt, met_init_cnt: std_logic_vector(CTR_W-1 downto 0);
  signal pwr_events_per_100us: std_logic_vector(11 downto 0);
  signal msk_len_min1_cycs: std_logic_vector(HDR_LEN_CYCS_W downto 0);
  signal hdr_rel_sum_i: std_logic_vector(FRAME_QTY_W-1 downto 0):=(others=>'0');
  signal hdr_sync_ctr: std_logic_vector(FRAME_PD_CYCS_W-1 downto 0);
  signal hdr_sync_ctr_atlim, hold_first_frame, hold_after, hdr_sync_dlyd_i: std_logic := '0';

  signal us100_pulse: std_logic;
begin

  
  corr_go <= corrstart_in and not corrstart_d;

  -- The "framer" just counts out a specified qty of frames
  framer_go <= corr_go or framer_go_4search;
  hold_first_frame <= search and (not hdr_found or hold_after or alice_txing);
  pd_timer_i: period_timer
    generic map (
      PD_LEN_W => FRAME_PD_CYCS_W,
      PD_QTY_W => FRAME_QTY_W)
    port map(
      clk  => clk,
      rst  => rst,
      free_run => '0',
      hold_first_frame => hold_first_frame,
    
      pd_len_cycs_min2 => frame_pd_min2, -- THIS IS WRONG
      cyc_ctr          => frame_cyc,
      pd_qty_min1      => frame_qty_min1,
      go               => framer_go,

      going          => framer_going,      -- high during all the periods
      pd_first       => pd_first,          -- high during first frame
      pd_start_pul   => pd_start_pul,      -- pulse at start of each frame
      pd_end_pul_pre => frame_end_pul_pre, -- pulse before end of each frame
      pd_end_pul     => frame_end_pul,     -- pulse at end of each frame
      pd_last        => framer_last);
  dbg_framer_going <= framer_going;

  -- Usually we can kick off the search for the header
  -- after a rise in power.
  --
  -- samps_in       ___ABCD
  -- hdr_pwr_det_i ____----
  -- search_go      ____-____
  -- frame_cyc           0123
  -- hdr_a(0)       ______ABC
  -- slice_go(0)    ______-__
  --
  -- samps_red_dly0     A1234
  -- samps_red_d0            A
  msk_len_min1_cycs <= hdr_len_min1_cycs&'0'; -- double it
  pwr_det_i: pwr_det
    generic map (
      PD_CYCS => 16,
      MSK_LEN_W => HDR_LEN_CYCS_W+1,
      SAMP_W  => SAMP_W)
    port map (
      clk            => clk,
      samps_in          => samps_in,
      hdr_pwr_thresh    => hdr_pwr_thresh,
      msk_len_min1_cycs => msk_len_min1_cycs,
      clr_max           => proc_clr_cnts_adc, -- clears max_avg_pwr_max
      pwr_avg           => pwr_avg,       -- current avg pwr
      pwr_event         => pwr_event_pre, -- means pwr is thresh above avg
      pwr_event_iso     => pwr_event_iso, -- "isolated" power event.
      pwr_avg_max       => pwr_avg_max);  -- max avg pwr since last clr
  dbg_pwr_event_iso <= pwr_event_iso;
  hdr_pwr_det_i <= pwr_event_pre and met_init;

  tk: timekeeper
    generic map (
      REF_HZ => 308.2e6)
    port map(
      refclk      => clk,
      us100_pulse => us100_pulse);


  -- count how many isolated power events occur within 100 us.
  pwr_event_ctr: event_ctr_periodic
    generic map (W => 12)
    port map(
      clk          => clk,
      event        => pwr_event_iso,
      periodic_pul => us100_pulse,
      rclk         => proc_clk,
      ctr          => pwr_events_per_100us);
  
  
  hdr_pwr_det <= pwr_searching; -- export for dbg

  -- When in search mode:
  -- Before any header has been found, start the slices
  -- when we see enough of a power increase.  After a header has been found,
  -- start the slices a little before we expect the header.

  pwr_search_go <= search and not hdr_found and hdr_pwr_det_i
                   and not pwr_searching;
--(search and not search_d)  
  framer_go_4search <=    (search and not search_d)
                          or (a_going and framer_last and frame_end_pul);
--                              and                  (not a_sync_ctr_atlim or dbg_hold));
                             
  search_go  <= search and u_if(hdr_found='1', hdr_sync_i,
                                hdr_pwr_det_i and not pwr_searching);
  hdr_found_out <= hdr_found;
  
  gen_hdr_go <= corr_starts_hdr or search_go;
  -- This generates a header sequence to compare against incomming data
  gen_hdr_i: gen_hdr
    generic map (
      HDR_LEN_W => HDR_LEN_CYCS_W)
    port map(
      clk         => clk,
      rst         => rst,
      osamp_min1  => osamp_min1,
      gen_en      => '0', -- NOT USED
      lfsr_state_ld      => '1', -- sampled when go_pulse=1
      lfsr_state_in      => lfsr_state_in,
      lfsr_state_nxt     => lfsr_state_nxt,
      lfsr_state_nxt_vld => lfsr_state_nxt_vld,
      
      go_pulse    => gen_hdr_go, -- restarts hdr if already going

      en          => '1',

      hdr_len_min1_cycs => hdr_len_min1_cycs,
      
--      cyc_cnt_down   => hdr_cnt_down,
      hdr_vld      => hdr_vld,
      hdr_end_pre  => hdr_end_pre,
      dout         => gen_hdr_out); -- valid 2 cycs after go_pulse
  hdr_a(0) <= gen_hdr_out;
  
  -- if NUM_SLICES < hdr_len, we have to take multiple "passes"
  -- through the slices to get one correlation.
  gen_slices: for k in 0 to NUM_SLICES-1 generate
  begin
    
    corr_slice_i: hdr_corr_slice
      generic map(
        SAMP_W         => REDUCED_SAMP_W,
        HDR_LEN_CYCS_W => HDR_LEN_CYCS_W,
        MAG_W          => MAG_W,
        SUM_SHFT_W     => SUM_SHFT_W)
      port map(
        clk       => clk,
        hdr_in    => hdr_a(k),
        start_in  => slice_go(k),
        hdr_end_pul => slice_done_p(k),
        
        samps_d0  => samps_red_d0,
        samps_d1  => samps_red_d1,
        samps_d2  => samps_red_d2,
        samps_d3  => samps_red_d3,

        sum_shft  => sum_shft,
        hdr_out   => hdr_a(k+1),
        corr_i_out => slice_corr_i_a(k),
        corr_q_out => slice_corr_q_a(k));
    
  end generate gen_slices;

  -- TODO: need a better name than lst.  last of what? clarify the concept.
  -- means last slice is done
  lst_vld <= slice_done(to_integer(unsigned(last_slice_min1)));
--  allpass_done_dlyd <= allpass_done_p(to_integer(unsigned(last_slice_min1)));


  -- MAX_SLICES presumed to be a power of two.
  pass_offset <= pass_ctr & u_rpt('0', u_bitwid(MAX_SLICES-1));


--  shreg_mag <= u_add_u(u_abs(shreg_i_a(0)), u_abs(shreg_q_a(0)));
  
  process(clk)
    variable k: integer;
  begin
    if (rising_edge(clk)) then
      rst_d <= rst;
      rst_pulse <= rst and not rst_d;
      
      init_event <= u_b2b(unsigned(pwr_avg) > unsigned(u_extl(init_thresh_d16 & "0000", SAMP_W)));
      met_init <= not (rst or not search)
                  and (met_init or init_event);
      met_init_d <= met_init;
      met_init_pulse <= met_init and not met_init_d;
      
      -- This is hi while doing a search after power-based kickoff:
      -- TODO: not sure of this last_vld here:
      searching <= (not lst_vld) and (search_go or searching);
      search_d <= search;
      search_pulse <= search and not search_d;

      hold_after <= search and (hold_after or
(a_going and framer_last and frame_end_pul
               and a_sync_ctr_atlim));
      
      pwr_searching <= not (rst or maxsofar_vld_d or not search)
                       and (pwr_search_go or pwr_searching);

      -- Goes high while alice is syncing to bobs pulses
      -- and while alice inserts headers
      a_going <= not (rst or not search or
                      (framer_last and frame_end_pul and not dbg_hold and a_sync_ctr_atlim))
                 and ((maxsofar_vld_d and hdr_det) or a_going);
      if ((not a_going
           or (framer_last and frame_end_pul and a_sync_ctr_atlim))='1') then
        a_sync_ctr <= (others=>'0');
        a_sync_ctr_atlim <= '0';
      elsif ((framer_last and frame_end_pul)='1') then
        a_sync_ctr <= u_inc(a_sync_ctr);
        a_sync_ctr_atlim <= u_b2b(unsigned(a_sync_ctr)=0);
      end if;
      
      hdr_pwr_det_d <= hdr_pwr_det_i;
      hdr_pwr_event <= pwr_search_go;
      
      -- msb gets priority, so this returns bit pos of msb
      sum_shft <= u_encode(hdr_len_min1_cycs, SUM_SHFT_W); -- TODO: dep on dsamp.
      
      if (lfsr_state_nxt_vld='1') then
        lfsr_state_sav <= lfsr_state_nxt;
      end if;
--      if (rst='1') then
--        lfsr_state_in <= "10100001111";
--      elsif (frame_end_pul_pre='1') then
--        lfsr_state_in <= lfsr_state_sav;
--      end if;
      
      if ((search or corrstart_in)='1') then
        lfsr_state_in <= lfsr_rst_st; -- was: "10100001111";
      elsif ((frame_end_pul and pass_ctr_atlim)='1') then
        lfsr_state_in <= lfsr_state_sav;
      end if;
      corrstart_d <= corrstart_in;




      
      -- There are multiple periods in one "pass".
      -- after the last pass, we have complete information.
      -- We know the max correlation of header with data,
      -- which is used for header detection.
      if ((   not going
           or (frame_end_pul and pass_ctr_atlim))='1') then
        pass_ctr       <= (others=>'0');
      elsif (frame_end_pul='1') then
        pass_ctr       <= u_inc(pass_ctr);
      end if;
      pass_ctr_atlim <= going and u_b2b(pass_ctr = num_pass_min1);

      -- TODO: rename this.  its more than a "period".  maybe "corr"
      -- Each period is multiple passes.  At the end of this period,
      -- we've checked for the start of the header everywhere.
      if ((not going
           or (frame_end_pul and pass_ctr_atlim and     pd_ctr_atlim))='1') then
        pd_ctr      <= frame_qty_min1;
      elsif ( (frame_end_pul and pass_ctr_atlim and not pd_ctr_atlim)='1') then
        pd_ctr      <= u_dec(pd_ctr);
      end if;
      pd_ctr_atlim <= u_b2b(unsigned(pd_ctr)=0);
      
--      if ((not going or rst)='1') then
--        passpd_sec <= '0';
--      elsif ((pass_ctr_atlim and frame_end_pul)='1') then
--        passpd_sec <= '1';
--      end if;

      

      
      -- going is high for num_pass*num_pds periods, while doing a correlation.
      going <= corrstart_in or (going and not (rst or (framer_last and frame_end_pul)));
      going_d <= going;

      -- During correlation, we start the header generator multiple times
      -- back-to-back within each frame.  The slices correlate with
      -- the output of the header generator.  So the slices also run
      -- multiple times during each frame.  This is called the first "pass".
      --
      -- If the header length (in cycles) is longer than the number of slices,
      -- one "pass" will not cover all possibilities of header starting
      -- locations.  We will need to do more "passes".  The second "pass",
      -- we start the hdr gen and
      -- slice zero at an "offset" from the start of the frame.
      -- This is pass_offset.  Each frame, the pass_offset is
      -- increased by the number of slices.

      corr_starts_hdr <= going and (u_b2b(frame_cyc = pass_offset) or hdr_restart);

--    starting the header generation (gen_hdr_go) and starting off the first slice
--    are part of the same mechanism.  The slices take the header sequence generated
--    by the hdr gen.
      gen_hdr_go_d <= gen_hdr_go;
--      if (gen_hdr_go_d='1') then
--        start <= std_logic_vector(to_unsigned(1, NUM_SLICES));
--      else
      slice_go <= slice_go(NUM_SLICES-2 downto 0) & gen_hdr_go_d;
      if (gen_hdr_go_d='1') then
        slice_0_cyc <= frame_cyc;
      end if;
      hdr_end_pul <= hdr_end_pre;
      hdr_end_d <= hdr_end_pul;
      slice_done <= slice_done(NUM_SLICES-2 downto 0) & hdr_end_d;
      slice_done_p(NUM_SLICES-1 downto 1) <= slice_done_p(NUM_SLICES-2 downto 0);
      qcorr_done <= slice_done_p(to_integer(unsigned(last_slice_min1)));      
      -- The following works because we assume pd_len is greater than
      -- last_slice_min1, which is less than the number of slices.
      -- Otherwise we would have to pipeline the signal
      if (rst='1') then
        allpass_end_pre <= '0';
      elsif (qcorr_done='1') then
        -- qcorr_done might occur first cyc of new pass 0,
        -- but pass_ctr_atlim stays hi one extra cyc so its ok.
        allpass_end_pre <= pass_ctr_atlim;
      end if;
      if (rst='1') then
        allpass_end <= '0';
      elsif (lst_vld='1') then
        allpass_end <= allpass_end_pre;
      end if;
-- In this example there are 3 slices operating.  Each header takes 4 cycles.
-- Each frame is 8 cycles, so a max of 2 headers fits into it.
-- There are two "passes"
-- allpass_donep(3) _____-______??
-- allpassdlyp(0)  _______-_____??


--
--
-- corrstart_in __-----
--
-- pass_ctr        0000000011111111      
-- pass_ctr_atlim  _________--------  (rename to _d)
-- allpass_done    ________________-__
--      
-- going        ___-------      
-- hdr_restart     _-___-___
-- corr_starts_hdr  _-___-___      
-- gen_hdr_go       _-___-____

-- framer_go    __---
-- frame_cyc    ...0123456701234567
-- frame_end_pul__________-_______-_
      
--  slice_go(0)     ___-______
--    hdr_in(0)     ...abcdABCD
--    hdr_in(2)     .....abcdABCD  
--    hdr_end_pul       __-____-____
--   slice_corr_*_a(0)     mmmm
--   slice_corr_*_a(2)       mmmm
--    lst_vld           _____-__

--   For CDM
--   shreg_vld              __----..-_      
--   shreg_*_a(0)             abcd  h

--   When searching, shreg is drained more slowly.
--
--   shreg_vld              __----------------_
--   sgreg_*_a(0)             aaaabbbbccccdddd
--   rshift_shft              ___-___-___-___-      
--   rshift_ctr               0000111122223333
--   cshift_ctr                0123012301230123
--   cshift_*_a(0)             abcdefghijklmnop      
--   maxsofar                   cccccccccccccccv     (c=possible change)
--   maxsofar_vld               _______________-___
      
      allpass_done      <= u_if(searching='1', lst_vld,
                                pass_ctr_atlim and frame_end_pul);
      allpass_done_p(0) <= allpass_done;
      allpass_done_p(NUM_SLICES-1 downto 1) <= allpass_done_p(NUM_SLICES-2 downto 0);
      allpass_dly_p(0) <= allpass_done_p(to_integer(unsigned(last_slice_min1)));
      allpass_dly_p(4 downto 1) <= allpass_dly_p(3 downto 0);
      allpass_pend <= allpass_dly_p(2) or (allpass_pend and shreg_vld);
      -- we want allpass_pend to stay high during shreg_vld.
      -- This indicator causes mag_max_shift to go high at the right time,
      -- which will take the max of the for mag_max_a()'s for a final overall max.


      --TODO: reconsider allpass_pend for searching case.  Not sure
      -- anymore.  Maybe dly_p is for correlator, not search.
      
      -- index of last slice currently in use:
      last_slice_min1 <= u_if(unsigned(hdr_len_min1_cycs)<NUM_SLICES,
                        hdr_len_min1_cycs(SLICE_IDX_W-1 downto 0),
                             std_logic_vector(to_unsigned(NUM_SLICES-1, SLICE_IDX_W)));
      last_slice_min2 <= u_dec(last_slice_min1);
      -- When correlating, restart header multiple times during one frame.
      -- The headers are restarted back-to-back.
      -- We don't count this. we don't know when the last one is, and the last one
      -- may be interrupted.
      -- But when searching triggered by rise in power, we don't restart the header.
      if ((not going or search or pd_start_pul or u_b2b(frame_cyc = pass_offset) or hdr_restart or frame_end_pul)='1') then
        hdr_restart_ctr <= hdr_len_min1_cycs;
        hdr_restart     <= '0'; -- not exactly
      else
        hdr_restart_ctr <= u_dec(hdr_restart_ctr);
        hdr_restart     <= u_b2b(unsigned(hdr_restart_ctr)=1);
      end if;
        
      pd_started <= pd_start_pul or (pd_started and not lst_vld_dd);
--      mags_vld_pre <= (not lst_vld_dd and mags_vld_pre) or (lst_vld_dd and pd_started);

      sampreddly_a(0) <= samps_red_pre;
      for k in 0 to SAMP_DLY-2 loop
        sampreddly_a(k+1)<= sampreddly_a(k);
      end loop;
      -- samps_red is same as sampreddly_a(end);
      samps_red_d0 <= samps_red;
      samps_red_d1 <= samps_red(6*REDUCED_SAMP_W-1 downto 0)
                      & samps_red_d0(8*REDUCED_SAMP_W-1 downto 6*REDUCED_SAMP_W);
      samps_red_d2 <= samps_red(4*REDUCED_SAMP_W-1 downto 0)
                      & samps_red_d0(8*REDUCED_SAMP_W-1 downto 4*REDUCED_SAMP_W);
      samps_red_d3 <= samps_red(2*REDUCED_SAMP_W-1 downto 0)
                      & samps_red_d0(8*REDUCED_SAMP_W-1 downto 2*REDUCED_SAMP_W);
      
      -- when last slice's output is valid,
      -- transfer them all to shift regs

      lst_vld_d <= lst_vld;
      lst_vld_dd <= lst_vld_d;

      -- Each slice ouputs four IQ pairs, corresponding to a magnitude.
      -- For CDM correlations, we need to keep these quads together
      -- in the CDM memory.
      
      -- We want to calc mag = |corr_i|+|corr_q| for each
      -- of the four sample-delays (columns) for each slice
      -- being used (rows) and then find the maximum magnitude.
      -- we also want to calculate atan2(corr_q,corr_i) for the largest mag.
      -- Rather than having NUM_SLICES*4 magnitide calculators,
      -- we shift all the values through a single calculator.
      -- We do one row shift, then four column shifts,
      -- another row shift, and so on.
      for k in 0 to NUM_SLICES-1 loop
        if (lst_vld='1') then
          shreg_i_a(k) <= slice_corr_i_a(k); -- each contains 4 "columns"
          shreg_q_a(k) <= slice_corr_q_a(k);
        elsif ((k<NUM_SLICES-1) and (rshift_shft='1')) then
          -- shreg shifts values down towards index 0.
          shreg_i_a(k) <= shreg_i_a(k+1);
          shreg_q_a(k) <= shreg_q_a(k+1);
        end if;
      end loop;

      -- This is high while shreg contains valid data.
      shreg_vld <= not rst and search
                   and (lst_vld or (shreg_vld and
                                    not (rshift_shft and rshift_ctr_atlim)));
      shreg_vld_d <= shreg_vld;
      if (lst_vld='1') then
        rshift_ctr <= (others=>'0');
        rshift_ctr_atlim <= '0';
      elsif (rshift_shft='1') then
        rshift_ctr <= u_inc(rshift_ctr);
        rshift_ctr_atlim <= u_b2b(rshift_ctr = last_slice_min2);
      end if;
      rshift_ctr_d <= rshift_ctr;
      
      if ((rst or lst_vld_d)='1') then
        cshift_ctr <= "00";
      elsif (shreg_vld_d='1') then
        cshift_ctr <= u_inc(cshift_ctr);
      end if;

      if ((lst_vld_d or (cshift_ctr_atlim and shreg_vld))='1') then
        -- load output of row shifter into column shifter
        for k in 0 to 3 loop
          cshift_i_a(k) <= shreg_i_a(0)(MAG_W*(k+1)-1 downto MAG_W*k);
          cshift_q_a(k) <= shreg_q_a(0)(MAG_W*(k+1)-1 downto MAG_W*k);
        end loop;
      else
        -- shift the column shifter
        for k in 0 to 2 loop
          cshift_i_a(k) <= cshift_i_a(k+1);
          cshift_q_a(k) <= cshift_q_a(k+1);
        end loop;
        cshift_i_a(3) <= (others=>'0'); -- not needed. makes simulation pretty
        cshift_q_a(3) <= (others=>'0');
      end if;
      
    end if;
  end process;

--        for k in 0 to 3 loop        
--          if (mag_max_new(k)='1') then
--            mag_max_a(k)     <= mag_out_a(k);

  
--  rshift_ctr_atlim <= shreg_vld and u_b2b(unsigned(rshift_ctr)=0);
  rshift_shft <= u_if(search='1', u_b2b(cshift_ctr="10"), shreg_vld);
  cshift_ctr_atlim <= u_b2b(cshift_ctr="11");
  
  -- take the magintude of the column shifter output
  cshift_mag <= u_add_u(u_abs(cshift_i_a(0)), u_abs(cshift_q_a(0)));

  -- This is a signed value, relative to the middle slice,
  -- which is NUM_SLICES/2.  We want next hdr to land there.
  -- If the hdr lands on the middle slice,
  -- hdr_cyc_rel will be zero.
  hdr_cyc_rel <= std_logic_vector(
        unsigned(u_extl(hdr_det_row, SLICE_IDX_W+2))
        - to_unsigned(NUM_SLICES/2, SLICE_IDX_W+2));
  
  hdr_cyc <= hdr_cyc_w(FRAME_PD_CYCS_W-1 downto 0);
  process(clk)
    variable k: integer;
  begin
    if (rising_edge(clk)) then

      if ((lst_vld_dd
           or (shreg_vld_d and
               u_b2b(unsigned(cshift_mag)>unsigned(maxsofar_mag))))='1') then
        -- record maximum seen so far         
        maxsofar_mag    <= cshift_mag;
        maxsofar_i      <= cshift_i_a(0);
        maxsofar_q      <= cshift_q_a(0);
        maxsofar_subcyc <= cshift_ctr; -- 0 to 3
        maxsofar_row    <= rshift_ctr_d; -- a slice index
      end if;
      maxsofar_vld <= cshift_ctr_atlim and not shreg_vld and search;
      maxsofar_vld_d <= maxsofar_vld;

      hdr_det <= maxsofar_vld and
                 u_b2b(unsigned(maxsofar_mag) > unsigned(hdr_thresh));
      
--      mag_out_a_d <= mag_out_a;
      if (hdr_det='1') then
        hdr_mag      <= maxsofar_mag;
        hdr_i        <= maxsofar_i;
        hdr_q        <= maxsofar_q;
        hdr_subcyc_i <= maxsofar_subcyc;
        hdr_det_row  <= maxsofar_row; -- IE slice
        hdr_det_changed <= u_b2b(hdr_det_row /= maxsofar_row) and hdr_found;
      end if;
      new_best <= maxsofar_vld and
                  u_b2b(unsigned(maxsofar_mag) > unsigned(best_mag));
      if ((rst or proc_clr_cnts_adc or not search)='1') then
        best_mag <= (others=>'0');
      elsif (new_best='1') then
        best_mag <= maxsofar_mag; -- really for dbg
      end if;
      hdr_found     <= search and (hdr_found or hdr_det) and not search_restart;
      hdr_found_d   <= hdr_found;
      hdr_found_dd  <= hdr_found_d;
      hdr_found_ddd <= hdr_found_dd;
      hdr_det_d <= hdr_det;
      if (hdr_det_d='1') then
        -- We subtract two more cycles to replicate gen_hdr_go.
        hdr_cyc_pre <= u_add_s(u_add_s(hdr_cyc_rel, std_logic_vector(to_signed(-2, SLICE_IDX_W+2))),
                               u_extl(slice_0_cyc, FRAME_PD_CYCS_W+1));
      end if;
      frame_pd <= u_inc(u_extl(frame_pd_min1, FRAME_PD_CYCS_W+1));
      hdr_det_dd <= hdr_det_d;
      if (hdr_det_dd='1') then
        -- add modulo frame_pd_min1
        if (hdr_cyc_pre(FRAME_PD_CYCS_W)='1') then
          -- if negative, it can be only a small negative number.
          hdr_cyc_w <= u_add_u(hdr_cyc_pre, frame_pd);
        elsif (unsigned(hdr_cyc_pre) > unsigned(frame_pd_min1)) then
          -- if over, can only be slightly over.
          hdr_cyc_w <= u_sub_u(hdr_cyc_pre, frame_pd);
        else
          hdr_cyc_w <= hdr_cyc_pre;
        end if;
      end if;
      hdr_det_ddd <= hdr_det_dd;
      
      hdr_sync_i <= u_b2b(hdr_cyc = frame_cyc) and hdr_found and framer_going;
                    
      hdr_dly_en <= hdr_sync_i or (hdr_dly_en and not hdr_sync_ctr_atlim);
      if (hdr_sync_i='1') then
        hdr_sync_ctr <= sync_dly;
        hdr_sync_ctr_atlim <= u_b2b(unsigned(sync_dly)=0);
      elsif (hdr_dly_en='1') then
        hdr_sync_ctr <= u_dec(hdr_sync_ctr);
        hdr_sync_ctr_atlim <= u_b2b(unsigned(hdr_sync_ctr)=1);
      end if;
      -- we generate hdr_sync_dlyd during the "second" stage of
      -- alice synchronization.  This is sent out to util_dacfifo
      -- to cause a header to be generated.
      hdr_sync_dlyd_i <= hdr_dly_en and hdr_sync_ctr_atlim
                         and (a_sync_ctr_atlim or alice_txing);

      
      -- hdr_cyc_rel is relative to hdr_cyc_first.      
      -- sum the hdr_cyc_rel's, to compute the mean.
      -- These are typically close to zero,
      -- so sum could be as large as frame_qty * some small number.
      if (hdr_found_d='0') then
        hdr_rel_sum_i <= u_extl(hdr_subcyc_i, FRAME_QTY_W);
      elsif (hdr_det_d='1') then
        hdr_rel_sum_i <= u_add_s(hdr_rel_sum_i,
                                 u_extl_s(hdr_cyc_rel, FRAME_QTY_W-2)&hdr_subcyc_i);
      end if;
      if ((hdr_found_ddd and not hdr_found_ddd)='1') then
        hdr_cyc_first <= hdr_cyc; -- save it.
      end if;
      -- software should divide the hdr_rel_sum by hdr_det_cnt,
      -- and add to hdr_cyc_first<<2.  The result is the mean
      -- starting sample in units of asamps.

      
      -- note: comparators must be in parallel to handle burst rate, but
      -- in practice there are many cycles available, so perhaps
      -- some of this could be serialized.
--      if (mag_max_shift='0') then
--        for k in 0 to 3 loop        
--          if (mag_max_new(k)='1') then
--            mag_max_a(k)     <= mag_out_a(k);
--            mag_max_cyc_a(k) <= frame_cyc;
--          end if;
--        end loop;
--        mag_max_shift     <= allpass_pend and not shreg_vld;
--        if ((allpass_pend and not shreg_vld)='1') then
--          mag_max_pre     <= (others=>'0');
--          mag_max_cyc_pre <= (others=>'0');
--        end if;
--        mag_max_shift_ctr <= "00";
--      else
--        if (unsigned(mag_max_a(0)) > unsigned(mag_max_pre)) then
--          mag_max_pre     <= mag_max_a(0);
--          mag_max_cyc_pre <= mag_max_cyc_a(0);
--          mag_max_ph_pre  <= mag_max_shift_ctr;
--        end if;
--        mag_max_a(3) <= (others=>'0');
--        mag_max_a(2 downto 0)     <= mag_max_a(3 downto 1);
--        mag_max_cyc_a(2 downto 0) <= mag_max_cyc_a(3 downto 1);
--        mag_max_shift_ctr <= u_inc(mag_max_shift_ctr);
--        mag_max_shift     <= not u_b2b(mag_max_shift_ctr="11");
--      end if;
--      mag_max_pre_vld <= mag_max_shift and u_b2b(mag_max_shift_ctr="11");


-- This mag_max gets assigned every time a new corr is found thats above
-- thresh. Currently it just replaces previous max.
-- Perhaps for diagnostics we want to calc a histogram of the cycles.
-- maybe not.      
--      if ((mag_max_gt_thresh and mag_max_pre_vld)='1') then
--        -- TODO: add a reg cycle here?
--        mag_max     <= mag_max_pre;
--        mag_max_cyc <= mag_max_cyc_pre;
--        mag_max_ph  <= mag_max_ph_pre;
--      end if;
      
      

      
      mem_waddr_inc <= (shreg_vld or mem_waddr_inc)
                       and not (mem_waddr_atlim and not framer_going);


      -- Note: mag_out_a is same as shreg_a(0)
      -- mag_add_a is valid same cyc as mag_out, so mem_dout vld then too.
      -- mem_raddr must be zero five cycles before that!
      --
      -- going by frame_cyc:
      -- the end of the hdr is valid (hdr_end_pul) at hdr_len_cycs+2
      -- The first corrslice is done two cycs after that,
      -- and then lst_vld is hi last_slice_min1 cycs after that.
      -- which is one cyc before shreg_a(0) is vld.
      -- So this is cyle hdr_len_cycs+2+2+last_slice_min1+1 - 5.
      raddr_inc_cyc <= u_add_u(hdr_len_min1_cycs, last_slice_min1);
      mem_rd <= (mem_rd or u_b2b(frame_cyc = raddr_inc_cyc))
                and not (mem_raddr_atlim and not framer_going);
      
      for k in 0 to 3 loop
        -- To zero memory on first pass, use:
        if (mem_firstpass='1') then
          if (shreg_vld='1') then
            mem_din_a(k) <= u_extl(mag_out_a(k), MEM_D_W);
          else
            mem_din_a(k) <= (others=>'0');
          end if;
        else
          mem_din_a(k)   <= u_add_u(mag_out_a(k), mem_dout_a(k));
        end if;
        -- The older way did not
        -- mem_din_a(k)   <= u_add_u(mag_out_a(k), mag_add_a(k));
        corr_dout_a(k) <= mem_din_a(k);
      end loop;
      mem_din_vld <= (mem_firstpass and mem_waddr_inc) or shreg_vld;
      -- old way:
      -- mem_din_vld <= shreg_vld;

      -- must make this change a cycle earlier.
      frame_pd_min2 <= u_dec(frame_pd_min1);
      mem_firstpass <= (corrstart_in or mem_firstpass) and not mem_waddr_atlim_pre;
      
--      mags_out_vld <= mags_out_vld or mags_out_first_i;
      if ((rst or mem_waddr_atlim)='1') then
        mem_waddr    <= (others=>'0');
--        use_mem_dout <= passpd_sec;
      elsif (mem_waddr_inc='1') then
        mem_waddr <= u_inc(mem_waddr);
      end if;

      if ((rst or mem_raddr_atlim)='1') then
        mem_raddr  <= (others=>'0');
      elsif (mem_rd='1') then
        mem_raddr <= u_inc(mem_raddr);
      end if;
      corr_vld_i <= ((mem_waddr_atlim_pre and framer_last) or corr_vld_i) and
                    not (mem_waddr_atlim_pre and not framer_going);
--      corr_vld_i <= ((mags_out_first_i and framer_last) or corr_vld_i) and not rst; -- TODO: when to clr? mags out first i?
--      pd_sec_dly <= pd_sec_dly(3 downto 0)&mem_raddr_atlim;
--      pd_sec <= pd_sec or pd_sec_dly(4);
    end if;
  end process;

  hdr_sync_dlyd <= hdr_sync_dlyd_i;
  
  dbg_hdr_det <= hdr_det; -- export for dbg
  met_init_o <= met_init; -- export for dbg
  
  slice_done_p(0) <= hdr_end_pul;



  mem_raddr_atlim <= u_b2b(mem_raddr=frame_pd_min1);
  mem_waddr_atlim <= u_b2b(mem_waddr=frame_pd_min1);
  mem_waddr_atlim_pre <= u_b2b(mem_waddr=frame_pd_min2);
  

  gen_sampred: for k in 0 to 7 generate
  begin
    samp_a(k)    <= samps_in((k+1)*SAMP_W-1 downto k*SAMP_W);
    -- discards lsbs and clips it
    sampred_a(k) <= u_clip_s(samp_a(k)(SAMP_W-1 downto G_CORR_DISCARD_LSBS), REDUCED_SAMP_W);
    
    -- reduce sample width
    samps_red_pre((k+1)*REDUCED_SAMP_W-1 downto k*REDUCED_SAMP_W) <=
      sampred_a(k);
    
--        u_clip_s(samps_in((k+1)*SAMP_W-1 downto     k*SAMP_W+4), REDUCED_SAMP_W);
  end generate gen_sampred;
  dbg_samps_red_pre <= samps_red_pre(REDUCED_SAMP_W-1 downto 0); -- to view in sim
  samps_red <= sampreddly_a(SAMP_DLY-1);
  dbg_samps_red <= samps_red(REDUCED_SAMP_W-1 downto 0); -- to view in sim
  
  -- For easy viewing in simulator:
  gen_dbg_out: for k in 0 to 3 generate
  begin
    --     (a|b) < c implies (a<c)&&(b<c)
    -- but (a|b) > c does not imply (a>c)||(b>c)
--    mag_max_new(k) <= shreg_vld and
--                      u_b2b(unsigned(mag_out_a(k))>unsigned(mag_max_a(k)));
    
--    mag_out_a(k) <= shreg_a(0)((k+1)*MAG_W-1 downto k*MAG_W);
    mem_din((k+1)*MEM_D_W-1 downto k*MEM_D_W) <= mem_din_a(k);
    mem_dout_a(k) <= mem_dout((k+1)*MEM_D_W-1 downto k*MEM_D_W);

--    mag_add_a(k) <= mem_dout_a(k) when (use_mem_dout='1')
--                    else (others=>'0');
--    corr_dout_a(k) <= mem_din_a(k);
    corr_out((k+1)*MEM_D_W-1 downto k*MEM_D_W) <= corr_dout_a(k);    
  end generate gen_dbg_out;
  corr_vld <= corr_vld_i;

  gen_use_corr: if (USE_CORR/=0) generate
  begin
  -- Memory to store sums
  mem_i: uram_infer
    generic map (
      C_AWIDTH => MEM_A_W,
      C_DWIDTH => MEM_W)
    port map(
      clk => clk,
      wea      => '1',
      mem_ena  => mem_din_vld,
      dina     => mem_din,
      addra    => mem_waddr,
--    douta =>

      web       => '0',
      mem_enb   => '1',
      dinb      => (others=>'0'),
      addrb     => mem_raddr,
      doutb     => mem_dout);
  end generate gen_use_corr;
  gen_n_use_corr: if (USE_CORR=0) generate
  begin
    mem_dout <= (others=>'0');
  end  generate gen_n_use_corr;
  hdr_sync    <= hdr_sync_i;
  hdr_subcyc  <= hdr_subcyc_i;

  hdr_found_samp: cdc_samp
    generic map( W=>1)
    port map (
      in_data(0)  => hdr_found,
      out_data(0) => hdr_found_pclk,
      out_clk     => proc_clk);
  hdr_det_cnt_clr <= not hdr_found_pclk;
  hdr_det_ctr_i: event_ctr
    generic map (W => CTR_W)
    port map(
      clk   => clk,
      event => hdr_det,
      rclk  => proc_clk,
      clr   => hdr_det_cnt_clr,
      cnt   => hdr_det_cnt); -- used with hdr_rel_sum

  -- For debug:
  event_v(0) <= rst_pulse;
  event_v(1) <= search_pulse;
  event_v(2) <= hdr_pwr_event;
  gen_event_ctrs: for k in 0 to EVENTS_QTY-1 generate
  begin
    event_ctr_i: event_ctr
      generic map (W => CTR_W)
      port map(
        clk   => clk,
        event => event_v(k),
        rclk  => proc_clk,
        clr   => proc_clr_cnts,
        cnt   => event_cnt_a(k));
  end generate gen_event_ctrs;
  rst_cnt     <= event_cnt_a(0);
  search_cnt  <= event_cnt_a(1);
  hdr_pwr_cnt <= event_cnt_a(2);

  
  clr_cnts_pb: cdc_pulse
    port map(
      in_pulse  => proc_clr_cnts,
      in_clk    => proc_clk,
      out_pulse => proc_clr_cnts_adc,
      out_clk   => clk);


  
  -- This implements the status array
  proc_dout_pre_a(0)(31)                          <= hdr_found;
  proc_dout_pre_a(0)(30)                          <= framer_going;
  proc_dout_pre_a(0)(29)                          <= met_init;
  proc_dout_pre_a(0)(28)                          <= pwr_searching;
  proc_dout_pre_a(0)(27 downto 26) <= (others=>'0');
  proc_dout_pre_a(0)(25 downto 2)  <= hdr_cyc;
  proc_dout_pre_a(0)(1 downto 0)                  <= hdr_subcyc_i;
--  proc_dout_pre_a(0) <= proc_dout_pre0;
  
--  proc_dout_pre_a(1) <= u_extl(maxsofar_mag, 16)&u_extl(hdr_mag, 16);
  proc_dout_pre_a(1)(25 downto 16) <= best_mag;
  proc_dout_pre_a(1)( 9 downto 0)  <= hdr_mag;
  
  proc_dout_pre_a(2)(27 downto 16) <= pwr_events_per_100us;
  proc_dout_pre_a(2)(15 downto  0) <= hdr_rel_sum_i;
  
  proc_dout_pre_a(3)(31 downto 16) <= hdr_det_cnt;
  proc_dout_pre_a(3)(15 downto 0)  <= hdr_pwr_cnt;

  proc_dout_pre_a(4)(31 downto 16) <= rst_cnt;
  proc_dout_pre_a(4)(15 downto 0)  <= search_cnt;

  proc_dout_pre_a(5)(31 downto 30) <= "00";
  proc_dout_pre_a(5)(29 downto 16) <= pwr_avg;
  proc_dout_pre_a(5)(15 downto 14) <= "00"; 
 proc_dout_pre_a(5)(13 downto  0) <= pwr_avg_max;

  proc_dout_pre_a(6)(25 downto 16) <= hdr_q;
  proc_dout_pre_a(6)( 9 downto  0) <= hdr_i;
  
  proc_dout_pre_a(7)(28 downto 25) <= hdr_cyc_rel;
  proc_dout_pre_a(7)(24 downto  0) <= hdr_cyc_w;

  proc_dout_pre_a(8)(23 downto 0) <= hdr_cyc_first;

  gen_proc_dout: for k in 0 to 8 generate
  begin
    samp_dout: cdc_samp
      generic map( W=> 32)
      port map (
        in_data   => proc_dout_pre_a(k),
        out_data  => proc_dout_a(k),
        out_clk   => proc_clk);
  end generate gen_proc_dout;
  
  process(proc_clk)
  begin
    if (rising_edge(proc_clk)) then
      proc_dout <= proc_dout_a(to_integer(unsigned(proc_sel)));
    end if;
  end process;


end architecture struct;
