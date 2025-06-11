
-- power-based header detection
-- uses manhattan distance, which should be enough
-- considering we expect >20 ext ratio between hdr and body.
--
-- Computes an average of power across the prior PD_CYCS cycles.
-- Of course, this lags the actual power.


-- 
--
-- samps_in   ___ABCD
-- det_flag   ____---

library ieee;
use ieee.std_logic_1164.all;
entity pwr_det is
  generic (
    PD_CYCS: integer;
    SAMP_W : integer); -- 12 - width of one sample from one ADC.
  port (
    clk            : in std_logic;
    samps_in       : in std_logic_vector(SAMP_W*8-1 downto 0);
    hdr_pwr_thresh : in std_logic_vector(SAMP_W-1 downto 0);
    avg_pwr        : out std_logic_vector(SAMP_W-1 downto 0); -- over period
    det_flag       : out std_logic);
end pwr_det;

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.util_pkg.all;
architecture struct of pwr_det is
  constant CTR_W: integer := u_bitwid(PD_CYCS-1);
  signal ctr: std_logic_vector(CTR_W-1 downto 0):=(others=>'0');
  signal ctr_atlim: std_logic;
  type samp_a_t is array(0 to 7) of std_logic_vector(SAMP_W-1 downto 0);
  signal samp_a: samp_a_t;
  type mag_a_t is array(0 to 3) of std_logic_vector(SAMP_W-1 downto 0);
  signal mag_a, mag_a_d: mag_a_t;
  signal dbg1, dbg2, dbg_max_mag, dbg_over: std_logic_vector(SAMP_W-1 downto 0);
  signal hdr_flag_i: std_logic_vector(3 downto 0):=(others=>'0');
  signal cur_mag_sum: std_logic_vector(2+SAMP_W-1 downto 0);
  signal mean, thresh: std_logic_vector(SAMP_W-1 downto 0);
  signal accum_nxt, accum, sum, cur_mag_mean: std_logic_vector(CTR_W+SAMP_W-1 downto 0) := (others=>'0');
begin
  gen_samp_a: for k in 0 to 7 generate
  begin
    samp_a(k) <= samps_in((k+1)*SAMP_W-1 downto k*SAMP_W);
  end generate gen_samp_a;
  gen_mag_a: for k in 0 to 3 generate
  begin
    mag_a(k) <= u_abs(samp_a(k))+u_abs(samp_a(k+4));
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
      if (ctr_atlim='1') then
        accum <= cur_mag_mean;
        sum   <= accum_nxt;
      else
        accum <= accum_nxt;
      end if;
      thresh <= u_add_u(mean, hdr_pwr_thresh);
      for k in 0 to 3 loop
        mag_a_d(k) <= mag_a(k);
        hdr_flag_i(k) <= u_b2b(unsigned(mag_a(k))>unsigned(thresh));
      end loop;
    end if;
  end process;
  avg_pwr <= mean;
  det_flag <= u_or(hdr_flag_i);
  
end architecture struct;
    
    
