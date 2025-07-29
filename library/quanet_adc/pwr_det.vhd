
-- power-based header detection
-- uses manhattan distance, which should be enough
-- considering we expect >20 ext ratio between hdr and body.
--
-- Also computes an average of power across the prior PD_CYCS cycles.
-- Of course, this lags the actual power.


-- For example, with a mask len of 4 cycles:
--
-- samps_in      ___ABCD___ABCD____N______
-- pwr_event     ____--_-___-_--____-_____
-- msk           _____----___----____----_
-- pwr_event_iso ____-______-_______-_____ 

library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
entity pwr_det is
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
    pwr_avg        : out std_logic_vector(SAMP_W-1 downto 0); -- over period
    pwr_avg_max    : out std_logic_vector(SAMP_W-1 downto 0); -- over period    
    pwr_event      : out std_logic;
    pwr_event_iso  : out std_logic; -- "isolated" power event.
    clr_max        : in std_logic);
end pwr_det;

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.util_pkg.all;
use work.cdc_pulse_pkg.all;
use work.cdc_samp_pkg.all;
architecture struct of pwr_det is
  constant CTR_W: integer := u_bitwid(PD_CYCS-1);
  signal ctr: std_logic_vector(CTR_W-1 downto 0):=(others=>'0');
  signal ctr_atlim, ctr_atlim_d: std_logic:='0';


  type mag_a_t is array(0 to 3) of std_logic_vector(SAMP_W-1 downto 0);
  signal mag_a, mag_a_d: mag_a_t;
  signal dbg1, dbg2, dbg_max_mag, dbg_over: std_logic_vector(SAMP_W-1 downto 0);
  signal event_v: std_logic_vector(3 downto 0):=(others=>'0');
  signal cur_mag_sum: std_logic_vector(2+SAMP_W-1 downto 0);
  signal mean, mean_max_i, thresh: std_logic_vector(SAMP_W-1 downto 0) := (others=>'0');
  signal accum_nxt, accum, sum, cur_mag_mean: std_logic_vector(CTR_W+SAMP_W-1 downto 0) := (others=>'0');

  signal msk_ctr: std_logic_vector(MSK_LEN_W-1 downto 0);
  signal msk_atlim, msk_en, event_i: std_logic:= '0';
begin

  gen_mag_a: for k in 0 to 3 generate
  begin
    mag_a(k) <= u_abs(samps_in_i(k)+samps_in_q(k));
  end generate gen_mag_a;

  dbg1 <=u_max_u(mag_a(0),mag_a(1));
  dbg2 <=u_max_u(mag_a(2),mag_a(3));
  dbg_max_mag <= u_max_u(dbg1, dbg2);
  dbg_over <= std_logic_vector(unsigned(dbg_max_mag)-unsigned(mean));
  
  -- this is the mean of the current 4 samps:
  cur_mag_mean <= u_extl(cur_mag_sum(2+SAMP_W-1 downto 2), CTR_W+SAMP_W);
  
  accum_nxt <= u_add_u(accum, cur_mag_mean);
  mean <= sum(CTR_W+SAMP_W-1 downto CTR_W); -- mean over averaging period
  process(clk)
  begin
    if (rising_edge(clk)) then
      cur_mag_sum <= u_add_u(u_add_u("00"&mag_a_d(0),"00"&mag_a_d(1)),
                             u_add_u("00"&mag_a_d(2),"00"&mag_a_d(3)));
      ctr <= u_dec(ctr);
      ctr_atlim <= u_b2b(ctr=1);
      ctr_atlim_d <= ctr_atlim;
      if (ctr_atlim='1') then
        accum <= cur_mag_mean;
        sum   <= accum_nxt; -- same as mean
      else
        accum <= accum_nxt;
      end if;
      if (clr_max='1') then
        mean_max_i <= (others=>'0');        
      elsif (ctr_atlim_d='1') then
        if (unsigned(mean) > unsigned(mean_max_i)) then
          mean_max_i <= mean;
        end if;
      end if;
      thresh <= u_add_u(mean, hdr_pwr_thresh);
      for k in 0 to 3 loop
        mag_a_d(k) <= mag_a(k);
        event_v(k) <= u_b2b(unsigned(mag_a(k))>unsigned(thresh));
      end loop;

      msk_en <= (event_i and (not msk_en or msk_atlim))
                or (msk_en and not msk_atlim);
      if ((not msk_en or msk_atlim)='1') then
        msk_ctr   <= msk_len_min1_cycs; -- a value of 0 is useless
        msk_atlim <= '0';
      else
        msk_ctr   <= u_dec(msk_ctr);
        msk_atlim <= u_b2b(unsigned(msk_ctr)<=1);
      end if;
      
    end if;
  end process;
  
  event_i <= u_or(event_v);
  pwr_event     <= event_i;
  pwr_event_iso <= event_i and (not msk_en or msk_atlim);
  pwr_avg  <= mean;
  pwr_avg_max <= mean_max_i;
  
end architecture struct;
    
    
