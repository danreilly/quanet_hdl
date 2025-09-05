library ieee;
use ieee.std_logic_1164.all;

package global_pkg is

  constant G_FWVER: integer := 3;


  
  constant G_OPT_GEN_PH_EST: integer := 1;
  constant G_OPT_GEN_CIPHER_FIFO: integer := 0;
  constant G_OPT_GEN_DECIPHER_LFSR: integer := 1;
  constant G_OPT_GEN_CDM_CORR: integer := 1;
  
  constant G_S_AXI_CLK_FREQ_HZ: real := 100.0e6;
  -- The duration of one frame (1 cyc = 4 asamps)
  constant G_FRAME_PD_CYCS_W : integer := 24;
  -- When using URAM for CDC, the frame period is limited by the amount
  -- of uram.  In that situation, this is the actual size:
  constant G_UFRAME_PD_CYCS_W : integer := 17;
  
  -- QSDC frames are shorter.
  constant G_QSDC_FRAME_CYCS_W : integer := 10;


  constant G_CIPHER_SYMLEN_W: integer := 6;
  -- The cipher fifo (which is NOT currently used, but suppose it were)
  -- holds the cipher for a full optical round trip.  So its depth
  -- times width must be of the same order as max round trip times TRNG generation
  -- rate, which could be about G_FRAME_PD_CYCS_W
  constant G_CIPHER_FIFO_A_W : integer := 8;
  constant G_CIPHER_FIFO_D_W : integer := 16;

  
  constant G_CIPHER_SYMLEN_ASAMPS_W: integer := 8;
  
  -- The transmit stuff (util_dacfifo) is clocked at a max of 308MHz,
  -- and processes at most four symbols per cycle.
  -- The length of the probe is in units cycles at 308.3MHz
  -- (if using on-off modulation, 1 symbol = 1 bit).
  constant G_HDR_LEN_W : integer := 8;

  -- we can oversample by the factor osamp
  -- though currently the oversampling is fixed.
  constant G_OSAMP_W : integer := 2;

  -- framee_qty is the number of probes to transmit consecutively.
  constant G_FRAME_QTY_W : integer := 16;
  
  constant G_CIPHER_CHAR_POLY : std_logic_vector(20 downto 0) := "010000000000000000001";
  constant G_CIPHER_RST_STATE : std_logic_vector(20 downto 0) := '0'&X"abcde";
  constant G_CIPHER_LFSR_W: integer := 21;

  constant G_MAX_CIPHER_M: integer := 4; -- max is 8-psk
  -- Note: the DAC MAX CIPHER M is 8 !!
  constant G_CIPHER_W : integer := 2; -- cipher bits per asamp (aka "chip")
  -- Note: the DAC CIPHER_W     is 3
  
  constant G_BODY_LEN_W : integer := 10;

  constant G_MAX_SLICES: integer :=  4;
  constant G_CORR_MAG_W: integer := 10;
  -- PASS_W = 
--  constant G_PASS_W : integer := u_bitwid((2**G_HDR_LEN_W+G_MAX_SLICES-1)/G_MAX_SLICES-1);
  constant G_PASS_W : integer := 6;


  constant G_CTR_W : integer := 4;

  -- number of LSBs the correlator discards
  constant G_CORR_DISCARD_LSBS : integer := 4;

  
  -- width of correlation values in correlation memory
  -- could be as high as 18
  constant G_CORR_MEM_D_W: integer := 16;

  constant G_QSDC_BITDUR_W : integer := 10;
  constant G_QSDC_BITCODE: std_logic_vector(9 downto 0) := "1010011010";
  constant G_QSDC_SYMS_PER_FR_W: integer := 9;
  constant G_QSDC_SUM_W: integer := 24;

  constant G_SYNC_REF_RXCLK : std_logic_vector(1 downto 0) := "00";
  constant G_SYNC_REF_PWR   : std_logic_vector(1 downto 0) := "01";
  constant G_SYNC_REF_CORR  : std_logic_vector(1 downto 0) := "10";
  constant G_SYNC_REF_TXDLY : std_logic_vector(1 downto 0) := "11";

  constant G_TXGOREASON_RXRDY: std_logic_vector(1 downto 0) := "00";
  constant G_TXGOREASON_RXPWR: std_logic_vector(1 downto 0) := "01";
  constant G_TXGOREASON_RXHDR: std_logic_vector(1 downto 0) := "10";
  constant G_TXGOREASON_ALWAYS: std_logic_vector(1 downto 0) := "11";

  
  -- This code often processes four adc/dac samples per cycle.
  -- This is so inherent it is not parameterizable.
  
-- The way AD originally wrote their code,
-- 14-bit ADC samples were always padded out to 16 samples.
-- This makes it easy to view this in simulation, and
-- in some cases the pad drops out during optimizaion,
-- but not always.
--
-- I wrote this in the interest of efficiency, but I follow
-- this AD convention when multiple samples are together in one vector.
-- In my code, the ADC SAMP_W is 14.  Or smaller if we want to discard bits.
-- And the sample plus pad is a "word", where WORD_W is 16.

  
  -- VHDL provides the concept of arrays of vectors,
  -- which verilog lacks.
  constant G_ADC_SAMP_W: integer:= 14;
  constant G_DAC_SAMP_W: integer:= 16;
  type g_adc_samp_array_t is array(0 to 3) of std_logic_vector(G_ADC_SAMP_W-1 downto 0);
  type g_dac_samp_array_t is array(0 to 3) of std_logic_vector(G_DAC_SAMP_W-1 downto 0);

  constant G_REDUCED_W: integer:= 8;
  type g_reduced_samp_array_t is array(0 to 3) of std_logic_vector(G_REDUCED_W-1 downto 0);

  function samp_array_to_vec(a: g_adc_samp_array_t)
    return std_logic_vector;
  
end global_pkg;

package body global_pkg is

  function samp_array_to_vec(a: g_adc_samp_array_t)
    return std_logic_vector is
  begin
    return a(3)&a(2)&a(1)&a(0);
  end function samp_array_to_vec;

  function vec_to_samp_array(v: std_logic_vector)
    return g_adc_samp_array_t is
    variable vv: std_logic_vector(v'length-1 downto 0);
    constant W: integer := v'length/4;
    variable a: g_adc_samp_array_t;
  begin
    for k in 0 to 3 loop
      a(k) := v((k+1)*W-1 downto k*W);
    end loop;
    return a;
  end function vec_to_samp_array;

end global_pkg;
