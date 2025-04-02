###############################################################################
## Copyright (C) 2019-2023 Analog Devices, Inc. All rights reserved.
### SPDX short identifier: ADIBSD
###############################################################################

source ../../../scripts/adi_env.tcl
source $ad_hdl_dir/projects/scripts/adi_project_xilinx.tcl
source $ad_hdl_dir/projects/scripts/adi_board.tcl

# get_env_param retrieves parameter value from the environment if exists,
# other case use the default value
#
#   Use over-writable parameters from the environment.
#
#    e.g.
#      make RX_JESD_L=4 RX_JESD_M=8 RX_JESD_S=1 TX_JESD_L=4 TX_JESD_M=8 TX_JESD_S=1
#      make RX_JESD_L=8 RX_JESD_M=4 RX_JESD_S=1 TX_JESD_L=8 TX_JESD_M=4 TX_JESD_S=1

#
# Parameter description:
#   JESD_MODE : Used link layer encoder mode
#      64B66B - 64b66b link layer defined in JESD 204C, uses Xilinx IP as Physical layer
#      8B10B  - 8b10b link layer defined in JESD 204B, uses ADI IP as Physical layer
#
#   RX_LANE_RATE :  Line rate of the Rx link ( MxFE to FPGA )
#   TX_LANE_RATE :  Line rate of the Tx link ( FPGA to MxFE )
#   [RX/TX]_JESD_M : Number of converters per link - 4 for a 4-channel ADC
#   [RX/TX]_JESD_L : Number of lanes per link
#   [RX/TX]_JESD_NP : Number of bits per sample, only 16 is supported
#   [RX/TX]_NUM_LINKS : Number of links, matches numer of MxFE devices

#   _S = samples per frame for each converter.  Ratio of sample rate to frame clock
#   _NP = bits per sample = 16bits for our stuff.

# Where FC is the frame clock frequency = word clk freq,
# which operates in FPGA and is typically 200..500MHz.
# lane rate (bps) = M * S * NP * coderate * FC / L
#  example:         4 * 4 * 16 * 10/8  * 250MHz / 8 = 10Gbps

# lane BW (sps) = M/L * S * FC
# lane BW (sps) = .5  * 4 * 250MHz = 0.5Gsps
# Then bytes per frame (I guess this is bytes per user's clk period) will be
# bytes_per_frame = M*S*NP / (8*L)
# example: = 4*4*16 / (8*4) = 16

# The max lane rate according to JESD204b specification
# is 12.5Gbps, but higher lane rates might be possible
# if the chips involved support it.

# The AD9081 reference manual (p1) says the AD9988 max
# max DAC (which has 4 channels) channel BW is 1.2GHz
# and max ADC (also 4 channels) channel BW is 1.6GHz.
# But a "channel" is not a lane.  These chips have eight lanes.

# Below there are 4 lanes at 10Gbps each
# I thought there were 8 at 16.5Gbps each.
# The zcu105 transcievers are capable of 16.3Gbps.
# Using 64b66b that is 15.6Gbits/s, whcich is almost 1Gsps
# The ad9988 lanes are capable of 24.75Gbps.
adi_project ad9081_fmca_ebz_zcu106 0 [list \
  JESD_MODE        [get_env_param JESD_MODE     8B10B ] \
  RX_LANE_RATE     [get_env_param RX_LANE_RATE   10 ] \
  TX_LANE_RATE     [get_env_param TX_LANE_RATE   10 ] \
  RX_JESD_M        [get_env_param RX_JESD_M          4 ] \
  RX_JESD_L        [get_env_param RX_JESD_L          8 ] \
  RX_JESD_S        [get_env_param RX_JESD_S          4 ] \
  RX_JESD_NP       [get_env_param RX_JESD_NP        16 ] \
  RX_NUM_LINKS     [get_env_param RX_NUM_LINKS       1 ] \
  RX_TPL_WIDTH     [get_env_param RX_TPL_WIDTH      {} ] \
  TX_JESD_M        [get_env_param TX_JESD_M          4 ] \
  TX_JESD_L        [get_env_param TX_JESD_L          8 ] \
  TX_JESD_S        [get_env_param TX_JESD_S          4 ] \
  TX_JESD_NP       [get_env_param TX_JESD_NP        16 ] \
  TX_NUM_LINKS     [get_env_param TX_NUM_LINKS       1 ] \
  TX_TPL_WIDTH     [get_env_param TX_TPL_WIDTH      {} ] \
  TDD_SUPPORT      [get_env_param TDD_SUPPORT        0 ] \
  SHARED_DEVCLK    [get_env_param SHARED_DEVCLK      1 ] \
  TDD_CHANNEL_CNT  [get_env_param TDD_CHANNEL_CNT    2 ] \
  TDD_SYNC_WIDTH   [get_env_param TDD_SYNC_WIDTH    32 ] \
  TDD_SYNC_INT     [get_env_param TDD_SYNC_INT       1 ] \
  TDD_SYNC_EXT     [get_env_param TDD_SYNC_EXT       0 ] \
  TDD_SYNC_EXT_CDC [get_env_param TDD_SYNC_EXT_CDC   0 ] \
]

adi_project_files ad9081_fmca_ebz_zcu106 [list \
  "system_top.v" \
  "system_constr.xdc"\
  "timing_constr.xdc"\
  "../../../library/common/ad_3w_spi.v"\
  "$ad_hdl_dir/library/common/ad_iobuf.v" \
  "$ad_hdl_dir/projects/common/zcu106/zcu106_system_constr.xdc" ]


adi_project_run ad9081_fmca_ebz_zcu106

