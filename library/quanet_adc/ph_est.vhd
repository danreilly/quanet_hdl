library ieee;
use ieee.std_logic_1164.all;
entity ph_est is
  generic (
    MAG_W: integer; -- number of bits used to store a correlation value
    DOUT_W: integer := 8;
    ADC_DATA_WIDTH: integer := 128);
  port (
    s_axi_aclk: in std_logic;
    
    -- fifo interface
    ph_i: in std_logic_vector(MAG_W-1 downto 0);
    ph_q: in std_logic_vector(MAG_W-1 downto 0);
    ph_vld: in std_logic;

    adc_rst: in std_logic;
    adc_data: in std_logic_vector(ADC_DATA_WIDTH-1 downto 0); -- data from ADC
    dout: out std_logic_vector(DOUT_W*4-1 downto 0);
    adc_clk: in std_logic);
end ph_est;

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.util_pkg.all;
use work.cdc_samp_pkg.all;
use work.cdc_pulse_pkg.all;
use work.global_pkg.all;
use work.period_timer_pkg.all;
architecture struct of ph_est is
  constant QUO_W: integer := 6;
  
  constant TRIG_W: integer := 9;
  -- The rom holds trig values (sin and cos)
  -- but it's "folded" for space efficiency.
  -- The ROM holds only half of one quadrant.
  constant ROM_W: integer := TRIG_W-1;
  
  constant COS45: std_logic_vector(TRIG_W-1 downto 0) :=
    std_logic_vector(to_unsigned(integer(0.70710678*2**(TRIG_W-1)), TRIG_W));

  component div
    generic (
      DIVIDEND_W: in integer;
      DIVISOR_W: in integer;
      QUO_W: in integer);
    port (
      clk : in std_logic;
      rst : in std_logic;
      dividend: in std_logic_vector(DIVIDEND_W-1 downto 0);
      divisor: in std_logic_vector(DIVISOR_W-1 downto 0);
      go:      in std_logic;
      
      result_vld: out std_logic;
      quo:     out std_logic_vector(QUO_W-1 downto 0);
      remain:  out std_logic_vector(DIVISOR_W-QUO_W-1 downto 0);
      divby0:  out std_logic);
  end component;
  
  component mult
    generic (
      A_W: integer;
      B_W: integer);
    port (
      clk  : in  std_logic;
      a : in  std_logic_vector(A_W-1 downto 0);
      b : in  std_logic_vector(B_W-1 downto 0);
      res: out std_logic_vector(A_W+B_W-1 downto 0));
  end component;

  component bit_dly
    generic (
      DLY_W  : integer;
      WORD_W : integer;
      D_W    : integer);
    port (
      clk : in std_logic;
      dly : in std_logic_vector(DLY_W-1 downto 0);
      din : in std_logic_vector(D_W-1 downto 0);
      dout : out std_logic_vector(D_W-1 downto 0));
  end component;
  
  
  component rom_xpm
    generic (
      FNAME: string;
      LATENCY: integer :=2;
      D_W: integer := 16;
      A_W: integer := 6);
    port (
      clk: in std_logic;
      rd   : in  std_logic; -- OPTIONAL.  does not really cause a read.  but times dout_vld.
      addr: in  std_logic_vector(A_W-1 downto 0);
      dout_vld : out std_logic; -- OPTIONAL.
      dout: out std_logic_vector(D_W-1 downto 0));
  end component;
  
  signal sgn_i, sgn_q, ph_vld_d, div_en, ph_45, div_vld,
    div_vld_d, div_vld_dd, rom_vld,
    iltq, iltq_pre: std_logic:='0';
  signal ph_mag, ph_i_abs, ph_q_abs, ph_i_abs_pre, ph_q_abs_pre, div_num
    : std_logic_vector(MAG_W-1 downto 0);
  signal div_numer: std_logic_vector(MAG_W+QUO_W-1 downto 0);
  signal div_quo: std_logic_vector(QUO_W-2 downto 0);

  signal rom_out: std_logic_vector(ROM_W*2-1 downto 0);
  signal ph_cos, ph_sin, ph_cos_p, ph_sin_p: std_logic_vector(TRIG_W-1 downto 0);

  constant MOUT_W: integer := DOUT_W+TRIG_W;
  type mout_a_t is array(0 to 3) of std_logic_vector(MOUT_W-1 downto 0);
  signal mout_0, mout_1, msum: mout_a_t;

  signal adc_data_dlyd: std_logic_vector(ADC_DATA_WIDTH-1 downto 0);

  type adc_data_a_t is array(0 to 3) of std_logic_vector(15 downto 0);
  signal adc_i_a, adc_q_a, adc_i_shftd, adc_q_shftd: adc_data_a_t;
  
begin
  
  ph_i_abs_pre <= u_abs(ph_i);  
  ph_q_abs_pre <= u_abs(ph_q);
  iltq_pre <= u_b2b(ph_i_abs_pre < ph_q_abs_pre);
  process(adc_clk)
  begin
    if (rising_edge(adc_clk)) then
      if (ph_vld='1') then
        iltq  <= iltq_pre;
        sgn_i <= ph_i(MAG_W-1);
        sgn_q <= ph_q(MAG_W-1);
        -- manhattan sum.  Instead of dividing by the norm 2 magnitude,
        -- dividing by the norm 1 mag is easier and good enough.
        ph_mag <= ph_i_abs_pre + ph_q_abs_pre;
        ph_i_abs <= ph_i_abs_pre;
        ph_q_abs <= ph_q_abs_pre;
      end if;


      ph_vld_d <= ph_vld;
      div_en   <= ph_vld_d;

      if (div_en='1') then
        ph_45 <= u_b2b(unsigned(ph_i_abs)=unsigned(ph_q_abs));
      end if;

        -- the lesser of sum_i_abs or sum_q_abs,
        -- go to the divider (below)
        -- and what comes back is div_quo

        -- table lookup to get cth, sth
        div_vld_d  <= div_vld;
        div_vld_dd <= div_vld_d;
        if (ph_45='1') then
          ph_cos_p <= COS45;
          ph_sin_p <= COS45;
        elsif (div_vld_d = '1') then
          ph_cos_p <= u_if(iltq='1', '0'&rom_out(ROM_W-1 downto 0),
                                     '0'&rom_out(ROM_W*2-1 downto ROM_W));
          ph_sin_p <= u_if(iltq='0', '0'&rom_out(ROM_W-1 downto 0),
                                     '0'&rom_out(ROM_W*2-1 downto ROM_W));
        end if;
        if (div_vld_dd='1') then
          ph_cos <= u_if(sgn_i='1', u_neg(ph_cos_p), ph_cos_p);
          ph_sin <= u_if(sgn_q='1', u_neg(ph_sin_p), ph_sin_p);
        end if;
      
        for k in 0 to 3 loop
          msum(k) <= u_add_s(mout_0(k), mout_1(k)); -- TODO: consider ovf
          
          -- divide msum by 2**(TRIG_W-1).  TODO: explain why not 2**TRIGW.
          dout((k+1)*DOUT_W-1 downto k*DOUT_W) <= msum(k)(MOUT_W-2 downto TRIG_W-1);
        end loop;

      
    end if;
  end process;
  div_num   <= u_if(iltq='1', ph_i_abs, ph_q_abs);
  div_numer <= div_num & u_rpt('0', QUO_W); -- mult by 2**QUO_W

  -- The greatest possible result of the division is one half.
  -- Since we mult by 2**QUOW, that is 2**(QUOW-1).
  -- We only need QUO_W-1 bits
  
  div_i: div
    generic map(
      DIVIDEND_W => MAG_W+QUO_W,
      DIVISOR_W  => MAG_W,
      QUO_W      => QUO_W-1)
    port map (
      clk      => adc_clk,
      rst      => adc_rst,
      dividend => div_numer,
      divisor  => ph_mag,
      go       => div_en,
      quo      => div_quo,
      result_vld  => div_vld);

 
  rom_i: rom_xpm
    generic map (
      FNAME => "../trig_rom.mem",
      LATENCY => 1,
      D_W => ROM_W*2,
      A_W => QUO_W-1)
    port map(
      clk      => adc_clk,
      rd       => div_vld,
      addr     => div_quo,
      dout_vld => rom_vld,
      dout     => rom_out);


  
  gen_mults: for k in 0 to 3 generate
    
    mult_0: mult
    generic map(
      A_W => DOUT_W,  -- 8
      B_W => TRIG_W) -- 9
      port map(
        clk  => adc_clk,
        a    => adc_i_a(k)(DOUT_W-1 downto 0),
        b    => ph_cos,
        res  => mout_0(k));
    
    mult_1: mult
    generic map(
      A_W => DOUT_W,  -- 8
      B_W => TRIG_W) -- 9
      port map(
        clk  => adc_clk,
        a    => adc_q_a(k)(DOUT_W-1 downto 0),
        b    => ph_sin,
        res  => mout_1(k));

    adc_i_a(k)  <= adc_data(k*32+15    downto k*32);
    adc_q_a(k)  <= adc_data(k*32+15+16 downto k*32+16);
--    multin_i_a(k) <= adc_i_a(k)(DOUT_W-1 downto 0);
--    multin_q_a(k) <= adc_q_a(k)(DOUT_W-1 downto 0);
--    multin_i_ovf(k) <= adc_i_a(k)(DOUT_W-1) xor adc_i_a(k)(DOUT_W);
--    multin_q_ovf(k) <= adc_q_a(k)(DOUT_W-1) xor adc_q_a(k)(DOUT_W);
    
--    di_a(k)     <= adc_i_shftd(k)(AGCD_W-1 downto 0);
--    dq_a(k)     <= adc_q_shftd(k)(AGCD_W-1 downto 0);
    
  end generate gen_mults;
  
end architecture struct;

    
