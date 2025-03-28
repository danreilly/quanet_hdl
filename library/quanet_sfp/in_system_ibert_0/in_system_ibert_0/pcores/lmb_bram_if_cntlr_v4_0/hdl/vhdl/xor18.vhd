-------------------------------------------------------------------------------
-- xor18.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- (c) Copyright 2003-2015,2023 Advanced Micro Devices, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of AMD and is protected under U.S. and international copyright
-- and other intellectual property laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- AMD, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) AMD shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or AMD had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- AMD products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of AMD products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
------------------------------------------------------------------------------
-- Filename:        xor18.vhd
--
-- Description:
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--              xor18.vhd
--
-------------------------------------------------------------------------------
-- Author:          rolandp
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x"
--      reset signals:                          "rst", "rst_n"
--      generics:                               "C_*"
--      user defined types:                     "*_TYPE"
--      state machine next state:               "*_ns"
--      state machine current state:            "*_cs"
--      combinatorial signals:                  "*_com"
--      pipelined or register delay signals:    "*_d#"
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce"
--      internal version of output port         "*_i"
--      device pins:                            "*_pin"
--      ports:                                  - Names begin with Uppercase
--      processes:                              "*_PROCESS"
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library lmb_bram_if_cntlr_v4_0;
use lmb_bram_if_cntlr_v4_0.all;
use lmb_bram_if_cntlr_v4_0.lmb_bram_if_funcs.all;

entity XOR18 is 
  generic (
    C_TARGET   : TARGET_FAMILY_TYPE);
  port (
    InA : in  std_logic_vector(0 to 17);
    res : out std_logic);
end entity XOR18;

architecture IMP of XOR18 is

  component MB_LUT6 is
  generic (
    C_TARGET : TARGET_FAMILY_TYPE;
    INIT     : bit_vector := X"0000000000000000"
  );
  port (
    O  : out std_logic;
    I0 : in  std_logic;
    I1 : in  std_logic;
    I2 : in  std_logic;
    I3 : in  std_logic;
    I4 : in  std_logic;
    I5 : in  std_logic
  );
  end component MB_LUT6;

  component MB_MUXCY is
  generic (
    C_TARGET : TARGET_FAMILY_TYPE
  );
  port (
    LO : out std_logic;
    CI : in  std_logic;
    DI : in  std_logic;
    S  : in  std_logic
  );
  end component MB_MUXCY;

  component MB_XORCY is
  generic (
    C_TARGET : TARGET_FAMILY_TYPE
  );
  port (
    O  : out std_logic;
    CI : in  std_logic;
    LI : in  std_logic
  );
  end component MB_XORCY;

begin  -- architecture IMP

  Using_FPGA: if ( C_TARGET /= RTL ) generate 
    signal xor6_1   : std_logic;
    signal xor6_2   : std_logic;
    signal xor6_3   : std_logic;
    signal xor18_c1 : std_logic;
    signal xor18_c2 : std_logic;
  begin  -- generate Using_LUT6

    XOR6_1_LUT : MB_LUT6
      generic map(
        C_TARGET => C_TARGET,
        INIT => X"6996966996696996")
      port map(
        O    => xor6_1,
        I0   => InA(17),
        I1   => InA(16),
        I2   => InA(15),
        I3   => InA(14),
        I4   => InA(13),
        I5   => InA(12));

    XOR_1st_MUXCY : MB_MUXCY
      generic map(
        C_TARGET => C_TARGET)
      port map (
        DI => '1',
        CI => '0',
        S  => xor6_1,
        LO => xor18_c1);

    XOR6_2_LUT : MB_LUT6
      generic map(
        C_TARGET => C_TARGET,
        INIT => X"6996966996696996")
      port map(
        O    => xor6_2,
        I0   => InA(11),
        I1   => InA(10),
        I2   => InA(9),
        I3   => InA(8),
        I4   => InA(7),
        I5   => InA(6));

    XOR_2nd_MUXCY : MB_MUXCY
      generic map(
        C_TARGET => C_TARGET)
      port map (
        DI => xor6_1,
        CI => xor18_c1,
        S  => xor6_2,
        LO => xor18_c2);

    XOR6_3_LUT : MB_LUT6
      generic map(
        C_TARGET => C_TARGET,
        INIT => X"6996966996696996")
      port map(
        O    => xor6_3,
        I0   => InA(5),
        I1   => InA(4),
        I2   => InA(3),
        I3   => InA(2),
        I4   => InA(1),
        I5   => InA(0));

    XOR18_XORCY : MB_XORCY
      generic map(
        C_TARGET => C_TARGET)
      port map (
        LI => xor6_3,
        CI => xor18_c2,
        O  => res);
    
  end generate Using_FPGA;

  Using_RTL: if ( C_TARGET = RTL ) generate 
  begin 

    res <= InA(17) xor InA(16) xor InA(15) xor InA(14) xor InA(13) xor InA(12) xor
           InA(11) xor InA(10) xor InA(9) xor InA(8) xor InA(7) xor InA(6) xor
           InA(5) xor InA(4) xor InA(3) xor InA(2) xor InA(1) xor InA(0);    

  end generate Using_RTL;
end architecture IMP;
