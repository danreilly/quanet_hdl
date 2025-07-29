
-- This expects inputs to remain valid for a whole frame:
-- hdr_vld ___-______
-- hdr_i      aaaaaaa
-- hdr_q      aaaaaaa

library ieee;
use ieee.std_logic_1164.all;
use work.global_pkg.all;
entity phase_est is
  generic (
    MAG_W: integer;
      TRIG_W: integer);
  port(
    clk           : in std_logic;
    en             : in std_logic;
    hdr_vld       : in std_logic;
    hdr_i         : in std_logic_vector(MAG_W-1 downto 0);
    hdr_q         : in std_logic_vector(MAG_W-1 downto 0);
    hdr_mag       : in std_logic_vector(MAG_W-1 downto 0);
    ph_cos : out std_logic_vector(TRIG_W-1 downto 0);
    ph_sin : out std_logic_vector(TRIG_W-1 downto 0));
end phase_est;

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
architecture struct of phase_est is

  -- The rom holds trig values (sin and cos)
  -- but it's "folded" for space efficiency.
  -- The ROM holds only half of one quadrant.
  -- all its contents are implicitly divided by 2^ROM_W,
  -- and they are all less than one.
  constant ROM_W: integer := TRIG_W-2;

  component rom_inf
    port (
      clk  : in std_logic;
      rd   : in  std_logic;
      addr : in  std_logic_vector(4 downto 0);
      dout_vld : out std_logic;
      dout   : out std_logic_vector(13 downto 0));
  end component;
  
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
      
      quo_vld: out std_logic;
      quo:     out std_logic_vector(QUO_W-1 downto 0);
      remain:  out std_logic_vector(DIVISOR_W-QUO_W-1 downto 0);
      divby0:  out std_logic);
  end component;

  constant QUO_W: integer := 6;

  constant COS45: std_logic_vector(TRIG_W-1 downto 0) :=
    std_logic_vector(to_unsigned(integer(0.70710678*2**(TRIG_W-1)), TRIG_W));
  
  signal sgn_i, sgn_q, iltq, iltq_pre, ph45_pre, ph45, ph0, div_go,
    rom_vld, rom_vld_d, div_rst,
    div_vld: std_logic;
  signal hdr_i_abs, hdr_q_abs,
    hdr_i_abs_pre, hdr_q_abs_pre, div_num, div_denom

    : std_logic_vector(MAG_W-1 downto 0);
  signal div_numer: std_logic_vector(MAG_W+QUO_W-1 downto 0);
  signal div_quo: std_logic_vector(QUO_W-2 downto 0);
  signal rom_out: std_logic_vector(ROM_W*2-1 downto 0);
  signal ph_cos_p, ph_sin_p: std_logic_vector(TRIG_W-1 downto 0);
  
begin
  hdr_i_abs_pre <= u_abs(hdr_i);  
  hdr_q_abs_pre <= u_abs(hdr_q);
  iltq_pre <= u_b2b(hdr_i_abs_pre < hdr_q_abs_pre);
  ph45_pre <= u_b2b(hdr_i_abs_pre = hdr_q_abs_pre);
  process(clk)
  begin
    if (rising_edge(clk)) then
      if (hdr_vld='1') then
        iltq  <= iltq_pre;
        ph45  <= ph45_pre;
        ph0   <= u_b2b(unsigned(div_num)=0);
        sgn_i <= hdr_i(MAG_W-1);
        sgn_q <= hdr_q(MAG_W-1);
        div_denom <= hdr_mag;

        -- manhattan sum.  Instead of dividing by the norm 2 magnitude,
        -- dividing by the norm 1 mag is easier and good enough.
      end if;
      div_go    <= hdr_vld;


      -- the lesser of sum_i_abs or sum_q_abs,
      -- go to the divider (below)
      -- and what comes back is div_quo

      -- table lookup to get cth, sth
--      div_vld_d <= div_vld;
--      div_vld_dd <= div_vld_d;
      if (ph45='1') then
        ph_cos_p <= COS45;
        ph_sin_p <= COS45;
      elsif (rom_vld = '1') then
        ph_cos_p <= u_if(iltq='0', '0'&ph0&rom_out(ROM_W*2-1 downto ROM_W),
                                   "00"&rom_out(ROM_W-1 downto 0));
        ph_sin_p <= u_if(iltq='1', '0'&ph0&rom_out(ROM_W*2-1 downto ROM_W),
                                   "00"&rom_out(ROM_W-1 downto 0));
      end if;
      if (en='0') then
        ph_cos <= "01"&u_rpt('0',TRIG_W-2);
        ph_sin <= (others=>'0');
      elsif (rom_vld_d='1') then
        ph_cos <= u_if(sgn_i='1', u_neg(ph_cos_p), ph_cos_p);
        ph_sin <= u_if(sgn_q='1', u_neg(ph_sin_p), ph_sin_p);
      end if;

    end if;
  end process;

  div_num   <= u_if(iltq='1', hdr_i_abs_pre, hdr_q_abs_pre);
  div_numer <= div_num & u_rpt('0', QUO_W); -- mult by 2**QUO_W
  -- This normalizes the IQ vector.
  -- The greatest possible result of the division is one half.
  -- Since we mult numerator by 2**QUOW, that is 2**(QUOW-1).
  -- We only need QUO_W-1 bits
  div_rst <= not en;
  div_i: div
    generic map(
      DIVIDEND_W => MAG_W+QUO_W,
      DIVISOR_W  => MAG_W,
      QUO_W      => QUO_W-1)
    port map (
      clk      => clk,
      rst      => div_rst,
      dividend => div_numer, -- min(|I|,|Q|)
      divisor  => div_denom, -- hdr_mag
      go       => div_go,
      quo      => div_quo,
      quo_vld  => div_vld);

  rom_i: rom_inf
    port map(
      clk      => clk,
      rd       => div_vld,
      addr     => div_quo,
      dout_vld => rom_vld,
      dout     => rom_out);
  
end struct;  
