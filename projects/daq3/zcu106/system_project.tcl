###############################################################################
## Copyright (C) 2014-2023 Analog Devices, Inc. All rights reserved.
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
#      make RX_JESD_L=4 RX_JESD_M=2 TX_JESD_L=4 TX_JESD_M=2 

# Parameter description:
#   [RX/TX]_JESD_M : Number of converters per link
#   [RX/TX]_JESD_L : Number of lanes per link
#   [RX/TX]_JESD_S : Number of samples per frame

# I think this builds just the block diagram:
adi_project daq3_zcu106 0 [list \
  RX_JESD_M    [get_env_param RX_JESD_M    2 ] \
  RX_JESD_L    [get_env_param RX_JESD_L    4 ] \
  RX_JESD_S    [get_env_param RX_JESD_S    1 ] \
  TX_JESD_M    [get_env_param TX_JESD_M    2 ] \
  TX_JESD_L    [get_env_param TX_JESD_L    4 ] \
  TX_JESD_S    [get_env_param TX_JESD_S    1 ] \
]

# Dan added my_gth.xci
adi_project_files daq3_zcu106 [list \
  "../common/daq3_spi.v" \
  "system_top.v" \
  "../../../library/quanet/util_pkg.vhd" \
  "../../../library/quanet/lfsr_w.vhd" \
  "happycamper/gth_driver.vhd" \
  "happycamper/my_gth_wrap.vhd" \
  "$ad_hdl_dir/library/common/ad_iobuf.v" \
  "ip/my_gth/my_gth.xci" \
  "ip/in_system_ibert_0/in_system_ibert_0.xci" \
  "system_constr.xdc" \
  "$ad_hdl_dir/projects/common/zcu106/zcu106_system_constr.xdc" ]


# The zc706 system_project.tcl also includes a zc706_plddr3_constr.xdc,
# which only defines loc and iostds for sys_clk and sys_rst.  But
# we use a board interface for sys_clk, and we handle sys_rst differently,
# because we feed it peripheral_reset from the main proc_sys_rst IP.

set_property strategy Performance_ExtraTimingOpt [get_runs impl_1]


adi_project_run daq3_zcu106


