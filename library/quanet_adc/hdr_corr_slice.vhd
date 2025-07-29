
-- This correlates incomming data with an incomming header sequence.
-- The input data is four I and Q samples per cycle.
-- start_in pulses high for one cycle, and the slice calculates
-- four correlation sums, checking whether the beginning of
-- a header commences in the start cycles. (0 bit delay,
-- 1 bit delay .. 3 bit delay).  The slice will be busy
-- for hdr_len_cycs cycles.


-- For example, suppose the header length is 4 cycles.
--
-- start_in  ___-___-____
-- hdr_in       abcdabcda
-- data in      abcd
-- acc           aBCDaBCD
-- mag_out           mmmmnnnn

-- above there is one asci char per cycle.  But really we process
-- four samples per cycle.  Currently it's the data that is
-- delayed by 0,1,2, or 3 samples (but perhaps the header should be
-- instead).
-- 
-- Below there are four asci chars per cycle

-- start_in    -    _    _    _    -
-- hdr_end_pul _    _    _    -    _
-- hdr_in      dcba hgfe lkji ponm
-- samps_d0    edcb ihgf mlkj  pon
-- samps_d1    dcba hgfe lkji ponm
-- samps_d2    cba  gfed kjih onml
-- samps_d3    ba   fedc jihg nmlk
-- acc_*_a(0)       a    B    C    D
-- acc_*_a(1)       a'   B'   C'   D'
-- acc_*_a(2)       a"   B"   C"   D"
-- corr_*_a(0)                         V

-- add_i_a(0) ++++
--



library ieee;
use ieee.std_logic_1164.all;
entity hdr_corr_slice is
  generic (
    SAMP_W : integer; -- 8 - reduced width of one sample from one ADC.
    HDR_LEN_CYCS_W: integer;
    MAG_W : integer := 8;
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
end hdr_corr_slice;
    
library ieee;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.util_pkg.all;
use work.global_pkg.all;
architecture struct of hdr_corr_slice is
  -- the +2 is because there are four values added per cycle.
  constant SUM_EXTRA_W: integer := u_bitwid(HDR_LEN_CYCS_W)+3; -- avoid ovf
  constant SUM_W: integer := SUM_EXTRA_W + SAMP_W;
  signal hdr_end_pul_d: std_logic := '0';
  signal hdr_in_d: std_logic_vector(3 downto 0);
--  type hdr_a_t is array(0 to 3) of std_logic_vector(3 downto 0);
--  signal hdr_a, start_a: hdr_a_t;

  type d_a_t is array(0 to 7) of std_logic_vector(SAMP_W-1 downto 0);
  signal din_a, din_neg_a, add_a: d_a_t;
  type d_in_a_t is array(0 to 15) of std_logic_vector(SAMP_W-1 downto 0);
  signal din_i_a, din_q_a: d_in_a_t;
  
  type samps_a_t is array(0 to 3) of std_logic_vector(8*SAMP_W-1 downto 0);
  signal samps_a: samps_a_t;
  
  type ddat_a_t is array(0 to 3) of std_logic_vector(4*SAMP_W-1 downto 0);
  signal ddat_i_a, ddat_q_a: ddat_a_t;

  type add_a_t is array(0 to 3) of std_logic_vector(SAMP_W+1 downto 0);
  signal add_i_a, add_q_a: add_a_t;
  
  type dbg_a_t is array(0 to 3) of std_logic_vector(SAMP_W+2 downto 0);  
  signal dbg_a: dbg_a_t;
  
  type sum_a_t is array(0 to 3) of std_logic_vector(SUM_W-1 downto 0);
  signal acc_i_a, acc_q_a, corr_i_pre_a, corr_q_pre_a: sum_a_t;
    

  
  type mag_a_t is array(0 to 3) of std_logic_vector(MAG_W-1 downto 0);
  signal corr_i_a, corr_q_a: mag_a_t := (others=>(others=>'0'));
  
  function corr_add(din: std_logic_vector(4*SAMP_W-1 downto 0); hdr: std_logic_vector)
    return std_logic_vector is
    variable samp: std_logic_vector(SAMP_W+1 downto 0);
    variable sum: std_logic_vector(SAMP_W+1 downto 0) := (others=>'0');
  begin
    for k in 0 to 3 loop
      samp := u_extl_s(din((k+1)*SAMP_W-1 downto k*SAMP_W), SAMP_W+2); -- extend signed
      sum := u_add_s(sum, u_if(hdr(k)='1', samp, u_neg(samp)));
    end loop;
    return sum;
  end function;
    
begin
  samps_a(0)<= samps_d0;
  samps_a(1)<= samps_d1;
  samps_a(2)<= samps_d2;
  samps_a(3)<= samps_d3;
  
  gen_per_samp: for d in 0 to 3 generate -- d = delay in samples
  begin
    -- hdr_a is array of 4 bits of header,
    -- each delayed one sample after its predecessor
--    hdr_a(d)   <=   hdr_in(3-d downto 0) & hdr_in_d(3 downto 4-d);

    gen_per_ss: for k in 0 to 3 generate -- d = delay in samples
    begin -- for view in sim
      din_i_a(d*4+k) <= samps_a(d)((k*2+1)*SAMP_W-1 downto     k*2*SAMP_W);
      din_q_a(d*4+k) <= samps_a(d)((k*2+2)*SAMP_W-1 downto (k*2+1)*SAMP_W);
    end generate gen_per_ss;
      
    ddat_i_a(d) <=   din_i_a(d*4+3)--(7*SAMP_W-1 downto 6*SAMP_W)
                   & din_i_a(d*4+2)--(5*SAMP_W-1 downto 4*SAMP_W)
                   & din_i_a(d*4+1)--(3*SAMP_W-1 downto 2*SAMP_W)
                   & din_i_a(d*4+0); --samps_a(d)(1*SAMP_W-1 downto 0*SAMP_W);
    ddat_q_a(d) <=   din_q_a(d*4+3) -- (8*SAMP_W-1 downto 7*SAMP_W)
                   & din_q_a(d*4+2)--(6*SAMP_W-1 downto 5*SAMP_W)
                   & din_q_a(d*4+1)--(4*SAMP_W-1 downto 3*SAMP_W)
                   & din_q_a(d*4+0); --(2*SAMP_W-1 downto 1*SAMP_W);
    add_i_a(d) <= corr_add(ddat_i_a(d), hdr_in);
    add_q_a(d) <= corr_add(ddat_q_a(d), hdr_in);
    

    -- pack corr_* arrays into a single vector, to pass out as a port
    corr_i_out((d+1)*MAG_W-1 downto d*MAG_W) <= corr_i_a(d);
    corr_q_out((d+1)*MAG_W-1 downto d*MAG_W) <= corr_q_a(d);

--    dbg_mag_pre_a(d) <= u_add_u(u_abs(acc_i_a(d)), u_abs(acc_q_a(d)));
--    dbg_mag_pre_a(d) <= std_logic_vector(unsigned(u_abs(acc_i_a(d))) + unsigned(u_abs(acc_q_a(d))));

    -- dont worry about ovf here because when i is big, q is small and vice versa.
    -- also we know msb is always 0 after absolute val.
--    abs_sum_a(d) <= u_add_u(u_abs(acc_i_a(d)), u_abs(acc_q_a(d)));

    -- Now we divide sums by header length
    corr_i_pre_a(d) <= u_shift_right_s(acc_i_a(d), sum_shft);
    corr_q_pre_a(d) <= u_shift_right_s(acc_q_a(d), sum_shft);
  end generate gen_per_samp;
  
  process(clk)
  begin
    if (rising_edge(clk)) then
--      hdr_in_d <= hdr_in;
      hdr_out  <= hdr_in;
      hdr_end_pul_d <= hdr_end_pul;
      for d in 0 to 3 loop -- four samples per cycle
        if (start_in='1') then
          -- assign add_*_a to acc_*_a
          acc_i_a(d) <= u_extl_s(add_i_a(d), SUM_W);
          acc_q_a(d) <= u_extl_s(add_q_a(d), SUM_W);

          -- ideally we divide mag_pre by hdr len, to normalize and reduce bits.
          
        else
          -- add add_*_a to acc_*_a
          acc_i_a(d) <= u_add_s(acc_i_a(d), add_i_a(d));
          acc_q_a(d) <= u_add_s(acc_q_a(d), add_q_a(d));
        end if;
        if (hdr_end_pul_d='1') then -- save sum
          -- These are the I/Q vectors that contain phase info.
          -- When abs values are added together, result will be
          -- (manhattan distance) correlation magnitude.
          corr_i_a(d) <= corr_i_pre_a(d)(MAG_W-1 downto 0);
          corr_q_a(d) <= corr_q_pre_a(d)(MAG_W-1 downto 0);
        end if;
      end loop;
    end if;
  end process;
  
end architecture struct;

