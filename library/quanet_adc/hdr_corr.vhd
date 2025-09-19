

-- For reflection monitoring, we are typically looking at small siganls.
-- So we discard the MSBs of the ADC samples.  This is called the
-- "reduced sample width".

-- If pilot starts in subcycle 0, and frame_go_dlyd=search_go is exactly correct,
-- hdr_det_o will happen ___ cycles later.
--    search_go - hdr_end_pul     1+hdr_len_cycs
--    hdr_end_pul - slices_done   1+num_slices
--    slices_done - hdr_det_o     2+4*num_slices+2
-- so latency is 6+hdr_len_cycs+5*num_slices


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
    do_stream     : in std_logic;
    corr_diff_rx_en : in std_logic;
    corr_mode_cdm : in std_logic;

    -- action signals    
    corrstart_in  : in std_logic; -- must be held hi.  lowering ends
    -- correlation gracefully.
    corr_resync_pul  : in std_logic;
    sync_starts_corr          : in std_logic;
    

    qsdc_track_en : in std_logic;

    search         : in std_logic;
    search_restart : in std_logic;

    
    dbg_hold : in std_logic;
    dbg_framer_going : out std_logic;
--    alice_syncing : in std_logic;
    alice_txing   : in std_logic;
    corr_w_same_hdr : in std_logic;
    frame_pd_min1 : in std_logic_vector(FRAME_PD_CYCS_W-1 downto 0);
--    num_pass_min1 : in std_logic_vector(u_bitwid((2**HDR_LEN_CYCS_W+MAX_SLICES-1)/MAX_SLICES-1)-1 downto 0);
    num_pass_min1 : in std_logic_vector(PASS_W-1 downto 0);
    hdr_len_min1_cycs : in std_logic_vector(HDR_LEN_CYCS_W-1 downto 0);
--    frame_qty_min1 : in std_logic_vector(FRAME_QTY_W-1 downto 0);
    itr_qty_min1 : in std_logic_vector(FRAME_QTY_W-1 downto 0);
    init_thresh_d16 : in std_logic_vector(7 downto 0); -- compared with power    
    hdr_pwr_thresh : in std_logic_vector(SAMP_W-1 downto 0); -- compared with power    
    hdr_thresh     : in std_logic_vector(MAG_W-1 downto 0);
    lfsr_rst_st    : in std_logic_vector(10 downto 0);    

--    samps_in  : in std_logic_vector(SAMP_W*8-1 downto 0);
    samps_in_i     : in g_adc_samp_array_t;
    samps_in_q     : in g_adc_samp_array_t;

    -- Once a header has been detected, this pulses periodically
    -- at the header period.  To be used in QSDC for payload insertion.
    dbg_pwr_event_iso : out std_logic; -- means sufficient power was detected
    hdr_pwr_det     : out std_logic; -- means sufficient power was detected
    
    hdr_det_o       : out std_logic; -- will preceed hdr sync
    hdr_i_o         : out std_logic_vector(MAG_W-1 downto 0);
    hdr_q_o         : out std_logic_vector(MAG_W-1 downto 0);
    hdr_gtt         : out std_logic;
    hdr_iq_vld      : out std_logic;
    
    hdr_mag_o       : out std_logic_vector(MAG_W-1 downto 0);
    
    met_init_o      : out std_logic;
    hdr_subcyc      : out std_logic_vector(1 downto 0);
    hdr_sync        : out std_logic;
    hdr_found_out   : out std_logic;
--    sync_dly        : in std_logic_vector(FRAME_PD_CYCS_W-1 downto 0);
--    hdr_sync_dlyd   : out std_logic;
    
    -- If this is computing correlations for CDM (lidar),
    -- the correlation values come out these ports:
    corr_vld_o: out std_logic;
    corr_out: out std_logic_vector(MEM_D_W*4-1 downto 0);

    -- Rather than convey each statistic up out through its own named port,
    -- they are indexed.  The processor reads them by first setting proc_sel,
    -- then reading proc_dout.
    proc_clk          : in std_logic;
    proc_clr_cnts     : in std_logic;
    proc_stat_mag_clr : in std_logic;
    proc_sel          : in std_logic_vector(3 downto 0);
    proc_dout         : out std_logic_vector(31 downto 0));
  
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
    do_stream : in std_logic;
    corr_diff_rx_en : in std_logic;
    corr_mode_cdm : in std_logic;
    
    corrstart_in  : in std_logic;
    corr_resync_pul  : in std_logic;
    sync_starts_corr          : in std_logic;
    qsdc_track_en : in std_logic; -- 1 = timing determined by frame_go_dlyd. (bob)
                                  -- 0 = tracks rxed headers and adapts
    -- ctl and status

    search        : in std_logic;

    search_restart : in std_logic;
    dbg_hold : in std_logic;
    dbg_framer_going : out std_logic;
--    alice_syncing  : in std_logic;
    alice_txing      : in std_logic;
    corr_w_same_hdr  : in std_logic;
    frame_pd_min1    : in std_logic_vector(FRAME_PD_CYCS_W-1 downto 0);
--    num_pass_min1  : in std_logic_vector(u_bitwid((2**HDR_LEN_CYCS_W+MAX_SLICES-1)/MAX_SLICES-1)-1 downto 0);
    num_pass_min1: in std_logic_vector(PASS_W-1 downto 0);
--    frame_qty_min1 : in std_logic_vector(FRAME_QTY_W-1 downto 0); -- really a period qty
    itr_qty_min1 : in std_logic_vector(FRAME_QTY_W-1 downto 0);
    hdr_len_min1_cycs  : in std_logic_vector(HDR_LEN_CYCS_W-1 downto 0);
    init_thresh_d16 : in std_logic_vector(7 downto 0); -- compared with power    
    hdr_pwr_thresh : in std_logic_vector(SAMP_W-1 downto 0); -- compared with power    
    hdr_thresh     : in std_logic_vector(MAG_W-1 downto 0);
    lfsr_rst_st    : in std_logic_vector(10 downto 0);    

--    samps_in  : in std_logic_vector(SAMP_W*8-1 downto 0);
    samps_in_i     : in g_adc_samp_array_t;
    samps_in_q     : in g_adc_samp_array_t;

-- Once a header has been detected, this pulses periodically
    -- at the header period.  To be used in QSDC for payload insertion.
    dbg_pwr_event_iso : out std_logic; -- means sufficient power was detected
    hdr_pwr_det     : out std_logic; -- will preceed hdr det
    
    hdr_det_o       : out std_logic; -- will preceed hdr sync
    hdr_i_o         : out std_logic_vector(MAG_W-1 downto 0);
    hdr_q_o         : out std_logic_vector(MAG_W-1 downto 0);
    hdr_gtt         : out std_logic;
    hdr_iq_vld      : out std_logic;

    hdr_mag_o       : out std_logic_vector(MAG_W-1 downto 0);
    
    met_init_o      : out std_logic;
    hdr_subcyc      : out std_logic_vector(1 downto 0);
    hdr_sync        : out std_logic;
    hdr_found_out   : out std_logic;
   
    -- If this is computing correlations for CDM (lidar),
    -- the correlation values come out these ports:
    corr_vld_o: out std_logic;
    corr_out: out std_logic_vector(MEM_D_W*4-1 downto 0);

    -- Rather than convey each statistic up out through its own named port,
    -- they are indexed.  The processor reads them by first setting proc_sel,
    -- then reading proc_dout.
    proc_clk: in std_logic;
    proc_clr_cnts : in std_logic;
    proc_stat_mag_clr : in std_logic;
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
use work.duration_ctr_pkg.all;
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
      samps_in_i     : in g_adc_samp_array_t;
      samps_in_q     : in g_adc_samp_array_t;
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
  signal itr_ctr: std_logic_vector(FRAME_QTY_W-1 downto 0);
  signal hdr_sync_i, hdr_dly_en, passpd_first, passpd_sav, passpd_sec, itr_ctr_atlim, use_mem_dout: std_logic := '0';
  
  signal allpass_done, allpass_pend: std_logic:='0';
  constant NUM_SLICES: integer := u_min(MAX_SLICES, 2**HDR_LEN_CYCS_W);
  signal slice_go, slice_done, allpass_done_p, slice_done_p, allpass_end_p: std_logic_vector(NUM_SLICES-1 downto 0) := (others=>'0');
  signal allpass_dly_p: std_logic_vector(4 downto 0) := (others=>'0');


  signal last_slice_min1, last_slice_min2, rshift_ctr, rshift_ctr_d: std_logic_vector(SLICE_IDX_W-1 downto 0) := (others=>'0');
  signal cshift_ctr: std_logic_vector(1 downto 0) := "00";
  signal shreg_shft, rshift_ctr_atlim, cshift_ctr_atlim: std_logic :='0';
  
--  type samp_a_t is array(0 to 7) of std_logic_vector(SAMP_W-1 downto 0);
--  signal samp_a: samp_a_t;
  -- The samples are reduced by some sort of AGC mechanism (not made yet)  

  signal sampred_i, sampred_q: g_reduced_samp_array_t;
  
  -- Then delayed so pwr-based detector has time to work.
  type sampreddly_a_t is array(0 to SAMP_DLY-1) of g_reduced_samp_array_t;
  signal sampreddly_i_a, sampreddly_q_a: sampreddly_a_t :=(others=>(others=>(others=>'0'))); 
  
  signal samps_vec,  samps_vec_d0, samps_vec_d1, samps_vec_d2, samps_vec_d3: std_logic_vector(8*REDUCED_SAMP_W-1 downto 0);
  signal samps_dlyd_i, samps_dlyd_q, samps_vec_i_pre,samps_vec_q_pre: g_reduced_samp_array_t;

  signal pwr_avg, pwr_avg_max: std_logic_vector(SAMP_W-1 downto 0);

  type hdr_a_t is array(0 to NUM_SLICES) of std_logic_vector(3 downto 0);
  signal hdr_a: hdr_a_t := (others=>(others=>'0'));

  type iqmags_a_t is array(0 to NUM_SLICES-1) of std_logic_vector(MAG_W*4-1 downto 0);
  signal slice_corr_i_a, slice_corr_q_a,
         shreg_i_a, shreg_q_a: iqmags_a_t := (others=>(others=>'0'));
  -- each element of array contains four correlation magnitudes

  type cmags_a_t is array(0 to 3) of std_logic_vector(MAG_W-1 downto 0);
  signal cshift_i_a, cshift_q_a,
    shreg_out_i_a, shreg_out_q_a, corr_i_a, corr_q_a
    : cmags_a_t;
  signal cshift_mag, maxsofar_mag, maxsofar_i, maxsofar_q,
    corrbest_i, corrbest_i_p, corrbest_i_pp, corrbest_01_i_ppp, corrbest_23_i_ppp,
    corrbest_q, corrbest_q_p, corrbest_q_pp, corrbest_01_q_ppp, corrbest_23_q_ppp,
    hdr_i, hdr_q, hdr_mag, hdr_mag_proc: std_logic_vector(MAG_W-1 downto 0);
  
  signal shreg_vld, shreg_vld_d,
    mem_din_vld,
    lastrun,
    qcorr_done, slices_done, slices_done_last_pass, slices_done_d, slices_done_dd,
    corr_starts_hdr, maxsofar_vld, maxsofar_vld_d,  proc_clr_cnts_adc,
    gen_hdr_go, gen_hdr_go_d, hdr_det_changed, new_best, -- hdr_det_cnt_clr,
    hdr_found, hdr_found_pclk, hdr_found_d, hdr_found_dd, hdr_found_ddd,
    hdr_det, hdr_det_d, hdr_det_dd, hdr_det_ddd: std_logic := '0';
  signal gen_hdr_out: std_logic_vector(3 downto 0) := "0000";
  signal mags_out_first_i, mags_out_vld, hdr_vld, hdr_end_pre, hdr_end_pul,
    allpass_end, allpass_end_pre, allpass_end_dlyd,
    hdr_end_d: std_logic := '0';  
--  signal rr_q: std_logic_vector(mag_w*4-1 downto 0) := (others=>'0');

  
  
  signal hdr_subcyc_i, maxsofar_subcyc: std_logic_vector(1 downto 0) := (others=>'0');
  signal hdr_cyc, hdr_cyc_first, slice_0_cyc,
    frame_cyc, mem_cyc_ctr: std_logic_vector(frame_pd_cycs_w-1 downto 0) := (others=>'0');
  signal hdr_cyc_w, hdr_cyc_pre, frame_pd: std_logic_vector(frame_pd_cycs_w downto 0) := (others=>'0');

  constant STATPD_W: integer := 10;
  signal statpd_frame_ctr, statpd_hdr_acc, statpd_hdr_cnt: std_logic_vector(STATPD_W-1 downto 0):=(others=>'0');
  signal statpd_mag_acc, statpd_mag_tot: std_logic_vector(MAG_W+STATPD_W-1 downto 0):=(others=>'0');
  signal statpd_hdr_acc_atlim, statpd_frame_ctr_atlim, stat_mag_clr, stat_mag_vld: std_logic := '0';
  

  type mag_a_t is array(3 downto 0) of std_logic_vector(mag_w-1 downto 0);
  type cyc_a_t is array(3 downto 0) of std_logic_vector(frame_pd_cycs_w-1 downto 0);



  
  signal  mag_out_a, mag_max_a, mag_out_a_d, mag_or_a, max_shreg_a: mag_a_t := (others=>(others=>'0'));
--  signal mag_max_new: std_logic_vector(3 downto 0) := "0000";
--  signal max_max_pulse, mag_max_shift, mag_max_pre_vld, mag_max_gt_thresh: std_logic:='0';
--  signal mag_max_shift_ctr: std_logic_vector(1 downto 0) := "00";  
--  signal mag_max, mag_max_proc: std_logic_vector(mag_w-1 downto 0);
--  signal mag_max_cyc_a: cyc_a_t;
  signal maxsofar_row, hdr_det_row: std_logic_vector(slice_idx_w-1 downto 0);
  signal hdr_cyc_rel: std_logic_vector(slice_idx_w+1 downto 0);
  signal mag_max_cyc_proc, mag_max_cyc: std_logic_vector(frame_pd_cycs_w-1 downto 0);
--  signal mag_max_ph: std_logic_vector(1 downto 0);

  
  
  signal max_max_vld: std_logic:='0';
  signal find_max_ctr: std_logic_vector(1 downto 0);
  signal find_max_en: std_logic;

  signal corr_go, corrstart_d, corr_go_dlyd,
    corr_start,
    framer_going, pd_first, pd_start_pul, framer_last, frame_end_pul,
    frame_end_pul_pre, pd_started, a_going, going, going_d, mags_vld_pre,
    framer_go, framer_go_4search: std_logic := '0';

  signal newsearch: std_logic;
  
  signal a_sync_ctr: std_logic_vector(1 downto 0);
  signal a_sync_ctr_atlim: std_logic;
  
  signal frame_pd_min2 : std_logic_vector(frame_pd_cycs_w-1 downto 0);
  
  constant mem_a_w : integer := u_min(u_max(12, frame_pd_cycs_w), g_uframe_pd_cycs_w);
--  constant mem_d_w : integer := mag_w+4; -- could be wider, even.
  constant mem_w   : integer := u_max(72, mem_d_w*4); -- four data words per entry
  
  signal mem_waddr_inc, mem_rd, pd_sec, mem_raddr_atlim, 
    mem_firstpass, mem_firstpass_d, mem_waddr_atlim, mem_waddr_atlim_pre,
    hdr_restart, corr_vld_p, corr_vld: std_logic:='0';
  signal hdr_restart_ctr, raddr_inc_cyc: std_logic_vector(hdr_len_cycs_w-1 downto 0);
  signal pd_sec_dly: std_logic_vector(4 downto 0) := (others=>'0');
  signal mem_din, mem_dout: std_logic_vector(mem_w-1 downto 0);
  signal mem_waddr, mem_raddr: std_logic_vector(mem_a_w-1 downto 0) := (others=>'0');
  type mem_data_a_t is array(3 downto 0) of std_logic_vector(mem_d_w-1 downto 0);
  signal mem_din_a, mem_dout_a, mag_add_a, corr_sum_a, corr_dout_a: mem_data_a_t;
  
  signal corrbest_ss_01_ppp, corrbest_ss_01_pppp,
         corrbest_ss_23_ppp, corrbest_ss_23_pppp,
    corrbest_ss_13_ppp,
    track_sync, track_sync_pend, corrbest_use,
    corrbest_last_ppp, corrbest_last_pp, corrbest_last_p, corrbest_last, corrbest_last_d,
    corrbest_first_ppp, corrbest_first_ppp_d, corrbest_first_pp, corrbest_pastfirst,
    corrbest_new_pp, corrbest_sync, o_corrbest_vld, o_corrbest_vld_d,
    o_corrbest_sync_pend, corrbest_sync_rsv, corrbest_gtt,
    corrbest_vld_ppp, corrbest_vld_p, corrbest_vld_p_d, corrbest_vld_pp, corrbest_vld_pp_d,
    corrbest_vld, corrbest_vld_d: std_logic := '0';
  signal o_corrbest_ss, corrbest_ss_pp, corrbest_ss_p, corrbest_ss: std_logic_vector(1 downto 0) := "00";
  signal o_corrbest, corrbest_01_ppp, corrbest_23_ppp, corrbest_pp, corrbest_p, corrbest,
    best_mag: std_logic_vector(mem_d_w-1 downto 0);

  
  signal corrbest_cyc_ppp, corrbest_cyc_pp, corrbest_cyc_p: std_logic_vector(frame_pd_cycs_w downto 0);
  signal corrbest_cyc: std_logic_vector(frame_pd_cycs_w-1 downto 0);

  signal o_corrbest_cyc: std_logic_vector(frame_pd_cycs_w-1 downto 0) := (others=>'0');

  
  signal lfsr_state_in, lfsr_state_nxt, lfsr_state_sav: std_logic_vector(10 downto 0) := (others=>'0');
  signal lfsr_state_nxt_vld, pwr_event_pre, pwr_event_iso, rst_d, rst_pulse, met_init_d, met_init_pulse,
    hdr_pwr_det_i, hdr_pwr_det_d, hdr_pwr_event, met_init, init_event,
    pwr_search_go, search_go, pwr_searching, searching, search_d, search_pulse: std_logic :='0';

  constant sum_shft_w: integer := u_bitwid(hdr_len_cycs_w-1);
  signal sum_shft: std_logic_vector(sum_shft_w-1 downto 0);

  constant num_proc_douts: integer := 16;
  type proc_dout_a_t is array(0 to num_proc_douts-1) of std_logic_vector(31 downto 0);
  signal proc_dout_pre_a, proc_dout_a: proc_dout_a_t := (others=>(others=>'0'));
  signal proc_dout_pre0: std_logic_vector(31 downto 0);

  constant ctr_w: integer := 16; -- frame_qty_w;
  constant events_qty: integer := 4;
  signal   event_v: std_logic_vector(events_qty-1 downto 0);
  type event_cnt_a_t is array(0 to events_qty-1) of std_logic_vector(ctr_w-1 downto 0);  
  signal event_cnt_a: event_cnt_a_t;
  
  signal corrbest_cnt, hdr_pwr_cnt, hdr_det_cnt, search_cnt, rst_cnt, met_init_cnt: std_logic_vector(ctr_w-1 downto 0);
  signal pwr_events_per_100us: std_logic_vector(11 downto 0);
  signal msk_len_min1_cycs, hdr_len_plus_cycs: std_logic_vector(hdr_len_cycs_w-1 downto 0);
  signal hdr_rel_sum_i: std_logic_vector(frame_qty_w-1 downto 0):=(others=>'0');


  
  signal hdr_sync_ctr: std_logic_vector(frame_pd_cycs_w-1 downto 0);
  signal hdr_sync_ctr_atlim, hold_first_frame, hold_after, hdr_sync_dlyd_i,
    qsdc_framer_go,qsdc_framer_pul, qsdc_rst, firstpass_pend: std_logic := '0';
  signal corr_end_pend, mem_rd_done, mem_wr_done: std_logic :='0';
  signal us100_pulse: std_logic;
begin

  
  corr_go <= ((corrstart_in and not corrstart_d) or corr_resync_pul);


  -- framer must go even if not tracking.
  framer_go <= corr_go or (corrstart_in and going and frame_end_pul and (not corr_end_pend or qsdc_track_en))
               or ( (not framer_going or frame_end_pul) and (qsdc_track_en or not corr_mode_cdm));


  pd_timer_i: period_timer
    generic map (
      pd_len_w => frame_pd_cycs_w)
    port map(
      clk  => clk,
      rst  => rst,
--      free_run => '0',
    
      pd_len_cycs_min2 => frame_pd_min2,
      cyc_ctr          => frame_cyc,
      go               => framer_go,

      going          => framer_going,      -- high during all the periods
--      pd_first       => pd_first,          -- high during first frame
      pd_start_pul   => pd_start_pul,      -- pulse at start of each frame
--      pd_end_pul_pre => frame_end_pul_pre, -- pulse before end of each frame
      pd_end_pul     => frame_end_pul);     -- pulse at end of each frame
--      pd_last        => framer_last);
  dbg_framer_going <= framer_going;

  -- usually we can kick off the search for the header
  -- after a rise in power.
  --
  -- samps_in       ___abcd
  -- hdr_pwr_det_i ____----
  -- search_go      ____-____
  -- frame_cyc           0123
  -- hdr_a(0)       ______abc
  -- slice_go(0)    ______-__
  --
  -- samps_vec_dly0     a1234
  -- samps_vec_d0            a
--  msk_len_min1_cycs <= hdr_len_min1_cycs&'0'; -- double it
  pwr_det_i: pwr_det
    generic map (
      pd_cycs   => 16,
      msk_len_w => hdr_len_cycs_w,
      samp_w    => samp_w)
    port map (
      clk               => clk,
      samps_in_i        => samps_in_i,
      samps_in_q        => samps_in_q,
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
      ref_hz => 308.2e6)
    port map(
      refclk      => clk,
      us100_pulse => us100_pulse);


  -- count how many isolated power events occur within 100 us.
  pwr_event_ctr: event_ctr_periodic
    generic map (w => 12)
    port map(
      clk          => clk,
      event        => pwr_event_iso,
      periodic_pul => us100_pulse,
      rclk         => proc_clk,
      ctr          => pwr_events_per_100us);
  
  
  hdr_pwr_det <= pwr_searching; -- export for dbg

  -- when in search mode:
  -- before any header has been found, start the slices
  -- when we see enough of a power increase.  after a header has been found,
  -- start the slices a little before we expect the header.

  pwr_search_go <= search and not hdr_found and hdr_pwr_det_i
                   and not pwr_searching;

--phaseout:  
--  framer_go_4search <=    (search and not search_d)
--  or (a_going and framer_last and frame_end_pul);
-- also had maybe but elided:  
-- --                              and                  (not a_sync_ctr_atlim or dbg_hold));

  
  search_go  <= search and u_if(hdr_found='1', sync_starts_corr,
                                               hdr_pwr_det_i and not pwr_searching);
  hdr_found_out <= hdr_found;

  -- track_sync simultaneous with sync_starts_corr is ok.
  gen_hdr_go <= corr_starts_hdr or (not corrbest_sync_rsv and (not track_sync_pend or track_sync) and sync_starts_corr) or search_go;
  
  -- this generates a header sequence to compare against incomming data
  gen_hdr_i: gen_hdr
    generic map (
      hdr_len_w => hdr_len_cycs_w)
    port map(
      clk         => clk,
      rst         => rst,
      osamp_min1  => osamp_min1,
      gen_diff           => corr_diff_rx_en,
      lfsr_state_ld      => '1', -- sampled when go_pulse=1
      lfsr_state_in      => lfsr_state_in,
      lfsr_state_nxt     => lfsr_state_nxt,
      lfsr_state_nxt_vld => lfsr_state_nxt_vld,
      
      go_pulse    => gen_hdr_go, -- restarts hdr if already going

      en          => '1',

      hdr_len_min1_cycs => hdr_len_min1_cycs,
      
      hdr_end_pre  => hdr_end_pre,
      dout_vld     => hdr_vld,
      dout         => gen_hdr_out); -- valid 2 cycs after go_pulse
  hdr_a(0) <= gen_hdr_out;
  
  -- if num_slices < hdr_len, we have to take multiple "passes"
  -- through the slices to get one correlation.
  gen_slices: for k in 0 to num_slices-1 generate
  begin
    
    corr_slice_i: hdr_corr_slice
      generic map(
        samp_w         => reduced_samp_w,
        hdr_len_cycs_w => hdr_len_cycs_w,
        mag_w          => mag_w,
        sum_shft_w     => sum_shft_w)
      port map(
        clk       => clk,
        hdr_in    => hdr_a(k),
        start_in  => slice_go(k),
        hdr_end_pul => slice_done_p(k),
        
        samps_d0  => samps_vec_d0,
        samps_d1  => samps_vec_d1,
        samps_d2  => samps_vec_d2,
        samps_d3  => samps_vec_d3,

        sum_shft  => sum_shft,
        hdr_out   => hdr_a(k+1),
        corr_i_out => slice_corr_i_a(k),
        corr_q_out => slice_corr_q_a(k));
    
  end generate gen_slices;

  -- this goes high after the last slice is done correlating.
  slices_done <= slice_done(to_integer(unsigned(last_slice_min1)));
--  allpass_done_dlyd <= allpass_done_p(to_integer(unsigned(last_slice_min1)));


  -- max_slices presumed to be a power of two.
  pass_offset <= pass_ctr & u_rpt('0', u_bitwid(max_slices-1));

  corr_go_dlyd_ctr: duration_ctr
    generic map(
      len_w => hdr_len_cycs_w)
    port map(
      clk      => clk,
      rst      => rst,
      go_pul   => corr_go,
      len_min1 => hdr_len_plus_cycs,
      sig_last => corr_go_dlyd);

  allpass_end_dlyd_ctr: duration_ctr
    generic map(
      len_w => hdr_len_cycs_w)
    port map(
      clk      => clk,
      rst      => rst,
      go_pul   => allpass_done,
      len_min1 => hdr_len_plus_cycs,
      sig_last => allpass_end_dlyd); -- a timo 

  
  process(clk)
    variable k: integer;
  begin
    if (rising_edge(clk)) then

      rst_d <= rst;
      rst_pulse <= rst and not rst_d;
      
      init_event <= u_b2b(unsigned(pwr_avg) > unsigned(u_extl(init_thresh_d16 & "0000", samp_w)));
      met_init <= not (rst or not search)
                  and (met_init or init_event);
      met_init_d <= met_init;
      met_init_pulse <= met_init and not met_init_d;
      
      -- this is hi while doing a search after power-based kickoff:
      -- the search ends after the last slice finishes
      searching <= (not slices_done) and (search_go or searching);
      search_d <= search;
      search_pulse <= search and not search_d;

      
      pwr_searching <= not (rst or maxsofar_vld_d or not search)
                       and (pwr_search_go or pwr_searching);

-- dont delete yet
--      
--      hold_after <= search and (hold_after or
--                                (a_going and framer_last and frame_end_pul
--                                 and a_sync_ctr_atlim));
-- 
--      -- goes high while alice is syncing to bobs pulses
--      -- and while alice inserts headers
--      a_going <= not (rst or not search or
--                      (framer_last and frame_end_pul and not dbg_hold and a_sync_ctr_atlim))
--                 and ((maxsofar_vld_d and hdr_det) or a_going);
--      if ((not a_going
--           or (framer_last and frame_end_pul and a_sync_ctr_atlim))='1') then
--        a_sync_ctr <= (others=>'0');
--        a_sync_ctr_atlim <= '0';
--      elsif ((framer_last and frame_end_pul)='1') then
--        a_sync_ctr <= u_inc(a_sync_ctr);
--        a_sync_ctr_atlim <= u_b2b(unsigned(a_sync_ctr)=0);
--      end if;
      
      hdr_pwr_det_d <= hdr_pwr_det_i;
      hdr_pwr_event <= pwr_search_go;
      
      -- msb gets priority, so this returns bit pos of msb
      -- the &1 added 8/20/25
      sum_shft <= u_encode(hdr_len_min1_cycs&'1', sum_shft_w); -- todo: dep on dsamp.
      
      if (lfsr_state_nxt_vld='1') then
        lfsr_state_sav <= lfsr_state_nxt;
      end if;
      
      if ((corr_w_same_hdr or corr_go)='1') then
        lfsr_state_in <= lfsr_rst_st;
      elsif (frame_end_pul='1') then
        lfsr_state_in <= lfsr_state_sav;
      end if;
      corrstart_d <= corrstart_in;

      
      -- there are multiple back-to-back header periods in one frame.
      -- each pass through a frame is counted by passs_ctr.
      -- after the last pass, we have complete information.
      if ((   not going
           or (frame_end_pul and pass_ctr_atlim))='1') then
        pass_ctr       <= (others=>'0');
      elsif (frame_end_pul='1') then
        pass_ctr       <= u_inc(pass_ctr);
      end if;
      pass_ctr_atlim <= going and u_b2b(pass_ctr = num_pass_min1);



      -- itr_qty is number of iterations of the integration.
      -- each iteration is multiple frames.  at the end of a iteration,
      -- we've checked for the start of the header everywhere once.
      if ((not going
           or (frame_end_pul and pass_ctr_atlim and     itr_ctr_atlim))='1') then
        itr_ctr      <= itr_qty_min1;
      elsif ( (frame_end_pul and pass_ctr_atlim and not itr_ctr_atlim)='1') then
        itr_ctr      <= u_dec(itr_ctr);
      end if;
      itr_ctr_atlim <= u_b2b(unsigned(itr_ctr)=0);
      

      
      -- going is high for num_pass*num_itr frames, while doing a correlation.
      going <= not rst and
              (corr_go or going) and not
              (corr_end_pend and frame_end_pul);
      going_d <= going;
      mem_rd_done <= rst or (mem_rd_done and not corr_go)
                     or (going and corr_end_pend and frame_end_pul);
      mem_wr_done <= (rst or not corrstart_in) or (mem_waddr_atlim_pre and mem_rd_done) or
                     (mem_wr_done and not corr_go_dlyd);

      -- during full correlation, we start the header generator multiple times
      -- back-to-back within each frame.  the slices correlate with
      -- the output of the header generator.  so the slices also run
      -- multiple times during each frame.  this is called the first "pass".
      --
      -- if the header length (in cycles) is longer than the number of slices,
      -- one "pass" will not cover all possibilities of header starting
      -- locations.  we will need to do more "passes".  the second "pass",
      -- we start the hdr gen and
      -- slice zero at an "offset" from the start of the frame.
      -- this is pass_offset.  each frame, the pass_offset is
      -- increased by the number of slices.

      corr_starts_hdr <= going and (u_b2b(frame_cyc = pass_offset) or hdr_restart);

--    starting the header generation (gen_hdr_go) and starting off the first slice
--    are part of the same mechanism.  the slices take the header sequence generated
--    by the hdr gen.
      gen_hdr_go_d <= gen_hdr_go;
--      if (gen_hdr_go_d='1') then
--        start <= std_logic_vector(to_unsigned(1, num_slices));
--      else
      slice_go <= slice_go(num_slices-2 downto 0) & gen_hdr_go_d;
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
      elsif (slices_done='1') then
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
-- corr_go      __-___      
-- going        ___-------      
-- corr_starts_hdr _-___-___      
-- gen_hdr_go   ____-___-____
-- corr_go      __-___      
-- framer_go    __-____
-- frame_cyc    ...0123456701234567
-- frame_end_pul__________-_______-_

--  search_go       _-____      
--  gen_hdr_go      _-____      
--  slice_go(0)     ___-___-____
--    hdr_in(0)     ...abcdABCD
--    hdr_in(2)     .....abcdABCD  
--    hdr_end_pul   ______-____-____
--  slice_done(0)   ________-____-___
--   slice_corr_*_a(0)     mmmm
--   slice_corr_*_a(2)       mmmm
--    slices_done           _____-__

--   For CDM
--   shreg_vld              __----..-_      
--   shreg_*_a(0)             abcd  h

--   When searching, shreg is drained more slowly.
--
--   shreg_vld              __----------------_
--   sgreg_*_a(0)             aaaabbbbccccdddd
--   shreg_shft               ___-___-___-___-      
--   rshift_ctr               0000111122223333
--   cshift_ctr                0123012301230123
--   cshift_*_a(0)             abcdefghijklmnop      
--   maxsofar                   cccccccccccccccv     (c=possible change)
--   maxsofar_vld               _______________-___
      
      allpass_done      <= u_if(searching='1', slices_done,
                                pass_ctr_atlim and frame_end_pul);
      allpass_done_p(0) <= allpass_done;
      allpass_done_p(NUM_SLICES-1 downto 1) <= allpass_done_p(NUM_SLICES-2 downto 0);
      allpass_dly_p(0) <= allpass_done_p(to_integer(unsigned(last_slice_min1)));
      allpass_dly_p(4 downto 1) <= allpass_dly_p(3 downto 0);
--      allpass_pend <= allpass_dly_p(2) or (allpass_pend and shreg_vld);
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
        
      pd_started <= pd_start_pul or (pd_started and not slices_done_dd);
--      mags_vld_pre <= (not slices_done_dd and mags_vld_pre) or (slices_done_dd and pd_started);

      sampreddly_i_a(0) <= sampred_i;
      sampreddly_q_a(0) <= sampred_q;
      for k in 0 to SAMP_DLY-2 loop
        sampreddly_i_a(k+1)<= sampreddly_i_a(k);
        sampreddly_q_a(k+1)<= sampreddly_q_a(k);
      end loop;
      

      samps_vec_d0 <= samps_vec;
      samps_vec_d1 <= samps_vec(6*REDUCED_SAMP_W-1 downto 0)
                      & samps_vec_d0(8*REDUCED_SAMP_W-1 downto 6*REDUCED_SAMP_W);
      samps_vec_d2 <= samps_vec(4*REDUCED_SAMP_W-1 downto 0)
                      & samps_vec_d0(8*REDUCED_SAMP_W-1 downto 4*REDUCED_SAMP_W);
      samps_vec_d3 <= samps_vec(2*REDUCED_SAMP_W-1 downto 0)
                      & samps_vec_d0(8*REDUCED_SAMP_W-1 downto 2*REDUCED_SAMP_W);
      
      -- when last slice's output is valid,
      -- transfer them all to shift regs (was called lst_vld)
      slices_done_d  <= slices_done;
      slices_done_dd <= slices_done_d;


      
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
        if (slices_done='1') then
          shreg_i_a(k) <= slice_corr_i_a(k); -- each contains 4 "columns"
          shreg_q_a(k) <= slice_corr_q_a(k);
        elsif ((k<NUM_SLICES-1) and (shreg_shft='1')) then
          -- shreg shifts values down towards index 0.
          shreg_i_a(k) <= shreg_i_a(k+1);
          shreg_q_a(k) <= shreg_q_a(k+1);
        end if;
      end loop;

      -- This is high while shreg contains valid data.
      shreg_vld <= not rst -- and search
                   and (slices_done or (shreg_vld and
                                    not (shreg_shft and rshift_ctr_atlim)));
      shreg_vld_d <= shreg_vld;
      if (slices_done='1') then
        rshift_ctr <= (others=>'0');
        rshift_ctr_atlim <= '0';
      elsif (shreg_shft='1') then
        rshift_ctr <= u_inc(rshift_ctr);
        rshift_ctr_atlim <= u_b2b(rshift_ctr = last_slice_min2);
      end if;
      rshift_ctr_d <= rshift_ctr;
      
      if ((rst or slices_done_d)='1') then
        cshift_ctr <= "00";
      elsif (shreg_vld_d='1') then
        cshift_ctr <= u_inc(cshift_ctr);
      end if;

      if ((slices_done_d or (cshift_ctr_atlim and shreg_vld))='1') then
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

      -- mult by 1.5
      msk_len_min1_cycs <= u_add_u(hdr_len_min1_cycs, '0'&hdr_len_min1_cycs(HDR_LEN_CYCS_W-1 downto 1));

      hdr_len_plus_cycs <= u_add_u(hdr_len_min1_cycs, std_logic_vector(to_unsigned(8, HDR_LEN_CYCS_W)));
    end if;
  end process;

--        for k in 0 to 3 loop        
--          if (mag_max_new(k)='1') then
--            mag_max_a(k)     <= mag_out_a(k);

  newsearch<='0';
  
--  rshift_ctr_atlim <= shreg_vld and u_b2b(unsigned(rshift_ctr)=0);
  shreg_shft <= u_if(newsearch='1', u_b2b(cshift_ctr="10"), shreg_vld);
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

      if ((slices_done_dd
           or (shreg_vld_d and
               u_b2b(unsigned(cshift_mag)>unsigned(maxsofar_mag))))='1') then
        -- record maximum seen so far         
        maxsofar_mag    <= cshift_mag;
        maxsofar_i      <= cshift_i_a(0);
        maxsofar_q      <= cshift_q_a(0);
        maxsofar_subcyc <= cshift_ctr; -- 0 to 3
        maxsofar_row    <= rshift_ctr_d; -- a slice index
      end if;
      maxsofar_vld <= cshift_ctr_atlim and not shreg_vld and newsearch;
      maxsofar_vld_d <= maxsofar_vld;

--      hdr_det <= maxsofar_vld and
--                 u_b2b(unsigned(maxsofar_mag) > unsigned(hdr_thresh));
      
      if (hdr_det='1') then
        hdr_mag      <= maxsofar_mag;
        hdr_i        <= maxsofar_i;
        hdr_q        <= maxsofar_q;
        hdr_subcyc_i <= maxsofar_subcyc;
        hdr_det_row  <= maxsofar_row; -- IE slice
        hdr_det_changed <= u_b2b(hdr_det_row /= maxsofar_row) and hdr_found;
      end if;
      
--      new_best <= maxsofar_vld and
--                  u_b2b(unsigned(maxsofar_mag) > unsigned(best_mag));
--      if ((rst or proc_clr_cnts_adc and not search)='1') then
--        best_mag <= (others=>'0');
--      elsif (new_best='1') then
--        best_mag <= maxsofar_mag; -- really for dbg
--      end if;
      
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
      
      hdr_sync_i <= u_b2b(hdr_cyc = frame_cyc) and hdr_found; -- and framer_going;
                    
--      hdr_dly_en <= hdr_sync_i or (hdr_dly_en and not hdr_sync_ctr_atlim);
--      if (hdr_sync_i='1') then
--        hdr_sync_ctr <= sync_dly;
--        hdr_sync_ctr_atlim <= u_b2b(unsigned(sync_dly)=0);
--      elsif (hdr_dly_en='1') then
--        hdr_sync_ctr <= u_dec(hdr_sync_ctr);
--        hdr_sync_ctr_atlim <= u_b2b(unsigned(hdr_sync_ctr)=1);
--      end if;
--      -- we generate hdr_sync_dlyd during the "second" stage of
--      -- alice synchronization.  This is sent out to util_dacfifo
--      -- to cause a header to be generated.
--      hdr_sync_dlyd_i <= hdr_dly_en and hdr_sync_ctr_atlim
--                         and (a_sync_ctr_atlim or alice_txing);

      
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
      
      

      
      
      -- old way:
      -- mem_din_vld <= shreg_vld;

      -- must make this change a cycle earlier.
      frame_pd_min2 <= u_dec(frame_pd_min1);

      -- end of full cdc correlation is near
      corr_end_pend <= itr_ctr_atlim and pass_ctr_atlim and (not corrstart_in or not do_stream);
        
      if (corrstart_in='0') then
        firstpass_pend <= '0';
      elsif (frame_end_pul='1') then
        firstpass_pend <= itr_ctr_atlim and pass_ctr_atlim and do_stream;
      end if;

      -- Could be set to 1 at reset, or after end too.
-- try use:  if (corrstart_in='0') then -- but no, what if corrstart_in is a pulse?
      if (going='0') then
        mem_firstpass <= '1';
      elsif (mem_waddr_atlim_pre='1') then
        mem_firstpass <= firstpass_pend;
      end if;
      mem_firstpass_d <= mem_firstpass;
      
--      mags_out_vld <= mags_out_vld or mags_out_first_i;
      if ((rst or mem_waddr_atlim)='1') then
        mem_waddr    <= (others=>'0');
      elsif (mem_waddr_inc='1') then
        mem_waddr <= u_inc(mem_waddr);
      end if;

      -- This is not the best but will do for now.
      
      mem_waddr_inc <= (shreg_vld or mem_waddr_inc)
                       and not mem_wr_done;

      if ((rst or mem_raddr_atlim)='1') then
        mem_raddr  <= (others=>'0');
      elsif (mem_rd='1') then
        mem_raddr <= u_inc(mem_raddr);
      end if;
      corr_vld_p <= (mem_waddr_atlim and itr_ctr_atlim and pass_ctr_atlim) or
                    (corr_vld_p and not mem_waddr_atlim);
      corr_vld   <= corr_vld_p;


      for k in 0 to 3 loop -- per subcycle
        -- when just tracking, we dont want to use mem_dout. The test is for mem_wr_done
        if ((mem_firstpass or mem_wr_done)='1') then
          if (shreg_vld='1') then
            mem_din_a(k) <= u_extl(mag_out_a(k), MEM_D_W);
            corr_i_a(k)  <= shreg_out_i_a(k);
            corr_q_a(k)  <= shreg_out_q_a(k);
          else -- zero memory on first pass
            mem_din_a(k) <= (others=>'0');
            corr_i_a(k)  <= (others=>'0');
            corr_q_a(k)  <= (others=>'0');
          end if;
        else
          mem_din_a(k) <= u_add_u(u_extl(mag_out_a(k), MEM_D_W), mem_dout_a(k));
          corr_i_a(k)  <= shreg_out_i_a(k);
          corr_q_a(k)  <= shreg_out_q_a(k);
        end if;
        corr_dout_a(k) <= mem_din_a(k);
      end loop;
      mem_din_vld <= (mem_firstpass and mem_waddr_inc) or shreg_vld;


      -- in streaming, mem_firstpass goes high one cyc before mem_waddr=0
      -- Whether or not we are tracking, a non-fullcorr "start" slices sets first.
      --
      -- For individual runs, corrbest_first should always be 1.
      corrbest_first_ppp   <=     mem_firstpass_d and mem_din_vld
                                  and (not corrbest_pastfirst or corrbest_first_ppp);
      -- perhaps could use allpass_end dlyd instead of mem_Rd.  but OK for now.
      corrbest_pastfirst <= mem_rd and (corrbest_first_ppp or corrbest_pastfirst); -- 0 for individ runs
      
      corrbest_first_ppp_d <= corrbest_first_ppp;
      
      -- Find best correlation
      if (mem_din_vld='0') then
        corrbest_ss_01_ppp <= '0';
        corrbest_01_ppp    <= (others=>'0');
        corrbest_ss_23_ppp <= '0';
        corrbest_23_ppp    <= (others=>'0');
        corrbest_cyc_ppp   <= (others=>'0');
      elsif (newsearch='0') then
        -- TODO: corrbest_ss_01_pppp is combo, seems like big fanout. add reg.
        corrbest_ss_01_ppp <=      corrbest_ss_01_pppp;
        corrbest_01_ppp    <= u_if(corrbest_ss_01_pppp='0',mem_din_a(0),mem_din_a(1));
        corrbest_01_i_ppp  <= u_if(corrbest_ss_01_pppp='0',corr_i_a(0), corr_i_a(1));
        corrbest_01_q_ppp  <= u_if(corrbest_ss_01_pppp='0',corr_q_a(0), corr_q_a(1));
        corrbest_ss_23_ppp <=      corrbest_ss_23_pppp;
        corrbest_23_ppp    <= u_if(corrbest_ss_23_pppp='0',mem_din_a(2),mem_din_a(3));
        corrbest_23_i_ppp  <= u_if(corrbest_ss_23_pppp='0',corr_i_a(2), corr_i_a(3));
        corrbest_23_q_ppp  <= u_if(corrbest_ss_23_pppp='0',corr_q_a(2), corr_q_a(3));
        corrbest_cyc_ppp   <= u_sub_u('0'&frame_cyc, u_extl(hdr_len_min1_cycs, FRAME_PD_CYCS_W+1));
      end if;
      corrbest_vld_ppp <= mem_din_vld and not newsearch;

      -- RUSHED. this might not be always correct.
--      lastrun <= (lastrun or (going and frame_end_pul and itr_ctr_atlim and pass_ctr_atlim))
--                 or (not going and gen_hdr_go);
      lastrun <= '0';

      -- cleared after corrbest_vld is past, or if timo
      allpass_pend      <= allpass_dly_p(2)
                           or (allpass_pend and not (not corrbest_vld_pp and corrbest_vld_pp_d)
                                                and not allpass_end_dlyd);
      corrbest_last_pp  <= corrbest_vld_ppp and allpass_pend; -- full frame multiitr
      
      if (corrbest_vld_ppp='1') then
        corrbest_ss_pp(0) <= u_if(corrbest_ss_13_ppp='0', corrbest_ss_01_ppp, corrbest_ss_23_ppp);
        corrbest_ss_pp(1) <= corrbest_ss_13_ppp;
        corrbest_pp       <= u_if(corrbest_ss_13_ppp='0', corrbest_01_ppp, corrbest_23_ppp);
        corrbest_i_pp     <= u_if(corrbest_ss_13_ppp='0', corrbest_01_i_ppp, corrbest_23_i_ppp);
        corrbest_q_pp     <= u_if(corrbest_ss_13_ppp='0', corrbest_01_q_ppp, corrbest_23_q_ppp);
        corrbest_cyc_pp   <= u_sub_u(corrbest_cyc_ppp, std_logic_vector(to_unsigned(12,FRAME_PD_CYCS_W+1)));
      end if;
      corrbest_vld_pp <= corrbest_vld_ppp;
      corrbest_vld_pp_d <= corrbest_vld_pp;
      corrbest_first_pp <= corrbest_first_ppp and not corrbest_first_ppp_d;
      
      -- when tracking, corrbest_first always starts out
      if (corrbest_vld_pp='1') then
        if ((corrbest_first_pp or corrbest_new_pp)='1') then
          corrbest_p      <= corrbest_pp;   -- the best so far
          corrbest_ss_p   <= corrbest_ss_pp;
          corrbest_i_p    <= corrbest_i_pp;
          corrbest_q_p    <= corrbest_q_pp;
          corrbest_cyc_p  <= corrbest_cyc_pp;
        end if;
        corrbest_last_p <= corrbest_last_pp; -- full frame multi itr
      end if;
      corrbest_vld_p   <= corrbest_vld_pp; -- hi for NUM_SLICES cycles
      corrbest_vld_p_d <= corrbest_vld_p;

      -- TODO: could threshold corrbest against lets say half the value of ocorr_best
      -- or some programmable thresh.

      -- The best in one "run" of slices.
      if ((not corrbest_vld_p and corrbest_vld_p_d)='1') then
        corrbest_gtt  <= u_b2b(unsigned(u_trunc(corrbest_p, MAG_W)) > unsigned(hdr_thresh));
        corrbest      <= corrbest_p;
        corrbest_use  <= (not going and not mem_rd) or corrbest_last_p; -- not intermed
        corrbest_i    <= corrbest_i_p;
        corrbest_q    <= corrbest_q_p;
        corrbest_ss   <= corrbest_ss_p;
        corrbest_last <= corrbest_last_p; -- full frame multi itr
        if (corrbest_cyc_p(FRAME_PD_CYCS_W)='1') then
          corrbest_cyc <= u_trunc(u_add_u(corrbest_cyc_p, frame_pd), FRAME_PD_CYCS_W);
        else
          corrbest_cyc <= u_trunc(corrbest_cyc_p, FRAME_PD_CYCS_W);
        end if;
      end if;
      corrbest_vld <= (not corrbest_vld_p and corrbest_vld_p_d); -- hi one cycle

      -- moved 9/2/25
      new_best <= corrbest_vld and
                  u_b2b(unsigned(corrbest) > unsigned(best_mag));
      if ((rst or proc_clr_cnts_adc)='1') then
        best_mag <= (others=>'0');
      elsif (new_best='1') then
        best_mag <= corrbest;
      end if;
      -- dont tons of gen hdr dets during full corr
      hdr_det <= (corrbest_vld and corrbest_gtt and corrbest_use);


      
      track_sync_pend <= qsdc_track_en and not corrbest_sync_rsv and
                         ((corrbest_vld and corrbest_gtt) or track_sync_pend) -- turn on
                         and not (track_sync or corr_go) -- turn off
                         and not (search and not search_d);
      track_sync      <= u_b2b(frame_cyc=corrbest_cyc) and track_sync_pend;
      
      
      -- overallbest in an entire full-frame multi-iter corrlation
      if ((corrbest_vld and corrbest_last)='1') then
        o_corrbest     <= corrbest;
        o_corrbest_ss  <= corrbest_ss;
        o_corrbest_cyc <= corrbest_cyc;
      end if;
      o_corrbest_vld    <= not corr_go and ((corrbest_last and corrbest_vld) or o_corrbest_vld);
      o_corrbest_vld_d  <= o_corrbest_vld;

      o_corrbest_sync_pend <= (qsdc_track_en and not corr_go)
                              and ((o_corrbest_vld and not o_corrbest_vld_d) or o_corrbest_sync_pend) -- turn on
                              and not corrbest_sync; -- turn off
      corrbest_sync_rsv <= qsdc_track_en and (corr_go or corrbest_sync_rsv) and not corrbest_sync;

--      -- we know best frame cyc for end of hdr
--      -- subtract 2 so sync starts early.
--      if (corrbest_vld='1') then
--        corrbest_cyc_w <= u_sub_u('0'&corrbest_cyc, std_logic_vector(to_unsigned(2, MEM_A_W+1)));
--      end if;
--      corrbest_vld_d <= corrbest_vld;
--      if (corrbest_vld_d='1') then
--        if (corrbest_cyc_w(MEM_A_W)='1') then
--          corrbest_fcyc <= u_trunc(u_add_u(corrbest_cyc_w, frame_pd), MEM_A_W);
--        else
--          corrbest_fcyc <= u_trunc(corrbest_cyc_w, MEM_A_W);
--        end if;
--      end if;
      corrbest_sync <= u_b2b(frame_cyc = o_corrbest_cyc) and o_corrbest_sync_pend;
--      corr_vld_p <= ((mags_out_first_i and framer_last) or corr_vld_p) and not rst; -- TODO: when to clr? mags out first i?
--      pd_sec_dly <= pd_sec_dly(3 downto 0)&mem_raddr_atlim;
--      pd_sec <= pd_sec or pd_sec_dly(4);
    end if;
  end process;

  corr_vld_o <= corr_vld;

  corrbest_ss_01_pppp <= u_b2b(unsigned(mem_din_a(0)) < unsigned(mem_din_a(1)));
  corrbest_ss_23_pppp <= u_b2b(unsigned(mem_din_a(2)) < unsigned(mem_din_a(3)));
  corrbest_ss_13_ppp  <= u_b2b(unsigned(corrbest_01_ppp) < unsigned(corrbest_23_ppp));
  corrbest_new_pp <= u_b2b(unsigned(corrbest_pp) > unsigned(corrbest_p));

  
  hdr_det_o <= hdr_det_d;
  
  hdr_mag_o  <= u_clip_u(corrbest, MAG_W);
  hdr_i_o    <= corrbest_i;
  hdr_q_o    <= corrbest_q;
  hdr_gtt    <= corrbest_gtt; -- greater than thresh
  hdr_iq_vld <= corrbest_vld;
  
  
  met_init_o  <= met_init; -- export for dbg
  
  slice_done_p(0) <= hdr_end_pul;



  mem_raddr_atlim <= u_b2b(mem_raddr=frame_pd_min1);
  mem_waddr_atlim <= u_b2b(mem_waddr=frame_pd_min1);
  mem_waddr_atlim_pre <= u_b2b(mem_waddr=frame_pd_min2);
  
  gen_lanes: for k in 0 to 3 generate
  begin
    -- discards lsbs and clips value
    -- Not exact but ok
    sampred_i(k) <= u_clip_s(samps_in_i(k)(SAMP_W-1 downto G_CORR_DISCARD_LSBS), REDUCED_SAMP_W);
    sampred_q(k) <= u_clip_s(samps_in_q(k)(SAMP_W-1 downto G_CORR_DISCARD_LSBS), REDUCED_SAMP_W);
  end generate gen_lanes;
  samps_dlyd_i <= sampreddly_i_a(SAMP_DLY-1);
  samps_dlyd_q <= sampreddly_q_a(SAMP_DLY-1);
  samps_vec <=   samps_dlyd_q(3)&samps_dlyd_i(3)
               & samps_dlyd_q(2)&samps_dlyd_i(2)
               & samps_dlyd_q(1)&samps_dlyd_i(1)
               & samps_dlyd_q(0)&samps_dlyd_i(0);

  gen_dbg_out: for k in 0 to 3 generate
  begin
    corr_out((k+1)*MEM_D_W-1 downto k*MEM_D_W) <= corr_dout_a(k);    
  end generate gen_dbg_out;


  -- ADDITIONAL STUFF FOR FULL CDC CORRELATION, IF BEING IMPLEMENTED
  gen_use_corr: if (USE_CORR/=0) generate
  begin
    
    gen_per_lane: for k in 0 to 3 generate
    begin
      mag_out_a(k) <= u_add_u(u_abs(shreg_i_a(0)((k+1)*MAG_W-1 downto k*MAG_W)),
                              u_abs(shreg_q_a(0)((k+1)*MAG_W-1 downto k*MAG_W)));
      shreg_out_i_a(k) <= shreg_i_a(0)((k+1)*MAG_W-1 downto k*MAG_W);
      shreg_out_q_a(k) <= shreg_q_a(0)((k+1)*MAG_W-1 downto k*MAG_W);
        
      mem_din((k+1)*MEM_D_W-1 downto k*MEM_D_W) <= mem_din_a(k);
      mem_dout_a(k) <= mem_dout((k+1)*MEM_D_W-1 downto k*MEM_D_W);
      
    end generate gen_per_lane;
    
    process(clk)
    begin
      if (rising_edge(clk)) then

        if ((not framer_going or (frame_end_pul and statpd_frame_ctr_atlim))='1') then
          statpd_frame_ctr <= (others=>'1');
        elsif (frame_end_pul='1') then
          statpd_frame_ctr <= u_dec(statpd_frame_ctr);
        end if;

        statpd_frame_ctr_atlim <= not u_or(statpd_frame_ctr);
        if ((not framer_going or (frame_end_pul and statpd_frame_ctr_atlim))='1') then
          statpd_hdr_acc <= (others=>'0');
          statpd_mag_acc <= (others=>'0');
        elsif ((hdr_det and not statpd_hdr_acc_atlim)='1') then
          statpd_hdr_acc <= u_inc(statpd_hdr_acc);
          statpd_mag_acc <= u_add_u(statpd_mag_acc, u_clip_u(corrbest, MAG_W));
        end if;
        if ((framer_going and frame_end_pul and statpd_frame_ctr_atlim)='1') then
          statpd_hdr_cnt   <= statpd_hdr_acc;
          statpd_mag_tot   <= statpd_mag_acc;
          stat_mag_vld     <= '1';
        elsif (stat_mag_clr='1') then
          stat_mag_vld     <= '0';
        end if;
        statpd_hdr_acc_atlim <= u_and(statpd_hdr_acc);

        -- Note: mag_out_a is same as shreg_a(0)
        -- mag_add_a is valid same cyc as mag_out, so mem_dout vld then too.
        -- mem_raddr must be zero five cycles before that!
        --
        -- going by frame_cyc:
        -- the end of the hdr is valid (hdr_end_pul) at hdr_len_cycs+2
        -- The first corrslice is done two cycs after that,
        -- and then slices_done is hi last_slice_min1 cycs after that.
        -- which is one cyc before shreg_a(0) is vld.
        -- So this is cyle hdr_len_cycs+2+2+last_slice_min1+1 - 5.
        raddr_inc_cyc <= u_add_u(hdr_len_min1_cycs, last_slice_min1);
        mem_rd <= (mem_rd or (going and u_b2b(frame_cyc = raddr_inc_cyc)))
                  and not (mem_raddr_atlim and mem_rd_done);

      end if;
    end process;
    
    -- Memory to store sums
    -- A single URAM has AWIDTH 12 and DWIDTH 72.
    -- 
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
  hdr_sync    <= corrbest_sync or track_sync;
  hdr_subcyc  <= hdr_subcyc_i;

  stat_mag_clr_samp: cdc_samp
    generic map(W=>1)
    port map (
      in_data(0)  => proc_stat_mag_clr,
      out_data(0) => stat_mag_clr,
      out_clk     => clk);

  
  hdr_found_samp: cdc_samp
    generic map( W=>1)
    port map (
      in_data(0)  => hdr_found,
      out_data(0) => hdr_found_pclk,
      out_clk     => proc_clk);

  -- also want rate of hdr detection. Say per 1024 frames.
  
-- TODO: need a rate of header detection.
-- N out of 1024 frames say.  

  -- also need max corr seen
  

--  hdr_det_cnt_clr <= not hdr_found_pclk;
  hdr_det_ctr_i: event_ctr
    generic map (W => CTR_W)
    port map(
      clk   => clk,
      event => hdr_det,
      rclk  => proc_clk,
      clr   => proc_clr_cnts,
      cnt   => hdr_det_cnt); -- used with hdr_rel_sum

  -- For debug:
  event_v(0) <= rst_pulse;
  event_v(1) <= search_pulse;
  event_v(2) <= hdr_pwr_event;
  event_v(3) <= corrbest_vld;
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
  rst_cnt      <= event_cnt_a(0);
  search_cnt   <= event_cnt_a(1);
  hdr_pwr_cnt  <= event_cnt_a(2);
  corrbest_cnt <= event_cnt_a(3);
  
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
  proc_dout_pre_a(1)(31 downto 16) <= o_corrbest;
  proc_dout_pre_a(1)(15 downto 0)  <= corrbest;
  
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

  proc_dout_pre_a(6)(25 downto 16) <= corrbest_q;
  proc_dout_pre_a(6)( 9 downto  0) <= corrbest_i;
  
  proc_dout_pre_a(7)(28 downto 25) <= hdr_cyc_rel;
  proc_dout_pre_a(7)(24 downto  0) <= hdr_cyc_w;

  proc_dout_pre_a(8)(23 downto 0) <= hdr_cyc_first;

  proc_dout_pre_a(9)(31 downto 16) <= (others=>'0');
  proc_dout_pre_a(9)(15 downto 0) <= corrbest_cnt;
  
  proc_dout_pre_a(10)(31)           <= stat_mag_vld;
  proc_dout_pre_a(10)(30 downto 10) <= u_clip_u(statpd_mag_tot, 21);
  proc_dout_pre_a(10)(9 downto 0)   <= u_extl(statpd_hdr_cnt, 10); -- hdrs det per 1024 frames

  gen_proc_dout: for k in 0 to 10 generate
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
