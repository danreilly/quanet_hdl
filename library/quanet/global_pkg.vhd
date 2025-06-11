library ieee;
use ieee.std_logic_1164.all;

package global_pkg is

  constant G_FWVER: integer := 2;
  
  -- The duration of one frame (1 cyc = 4 asamps)
  constant G_FRAME_PD_CYCS_W : integer := 24;
  -- QSDC frames are shorter.
  constant G_QSDC_FRAME_CYCS_W : integer := 12;

  
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
  constant G_BODY_CHAR_POLY : std_logic_vector(20 downto 0) := "010000000000000000001";
  constant G_BODY_RAND_BITS : integer := 4;
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

  constant G_QSDC_SYMS_PER_FR_W: integer := 9;
  
end global_pkg;

package body global_pkg is
end global_pkg;
