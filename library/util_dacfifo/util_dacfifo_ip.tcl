###############################################################################
## Copyright (C) 2015-2023 Analog Devices, Inc. All rights reserved.
### SPDX short identifier: ADIBSD
###############################################################################

# Look for the log of this in util_dacfifo_ip.log
# But later the IP is instantiated.  Look in
# daq3_zc706.gen/

# ip
source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip_xilinx.tcl

adi_ip_create util_dacfifo
adi_ip_files util_dacfifo [list \
  "$ad_hdl_dir/library/common/ad_mem.v" \
  "$ad_hdl_dir/library/common/ad_b2g.v" \
  "$ad_hdl_dir/library/quanet/util_pkg.vhd" \
  "util_dacfifo.v" \
  "$ad_hdl_dir/library/quanet/cdc_thru.vhd" \
  "$ad_hdl_dir/library/quanet/cdc_thru.xdc" \
  "$ad_hdl_dir/library/quanet/global_pkg.vhd" \
  "$ad_hdl_dir/library/quanet/lfsr_w.vhd" \
  "$ad_hdl_dir/library/quanet/pulse_bridge.vhd" \
  "$ad_hdl_dir/library/quanet/pulse_bridge.xdc" \
  "hdr_ctl.vhd" \
  "gen_hdr.vhd" \
  "util_dacfifo_ooc.ttcl" \
  "util_dacfifo_constr.xdc"]

# How do we tell it to use vhdl 2008?

# I think the AD wiki said to do this, and I tried it but it did not work.
# add_interface reg4_if conduit end
# add_interface_port reg4_if reg4 data Input 1
# Calling ipx::package_project did not even avoid generating a warning about source files not being in the IP directory!
# but I don't know how much that matters
#ipx::package_project -import_files "$ad_hdl_dir/library/common/lfsr_w.vhd"


#  "$ad_hdl_dir/library/common/ad_mem_asym.v" \
#  "$ad_hdl_dir/library/common/ad_g2b.v" \
#  "util_dacfifo_bypass.v" \


set_property scoped_to_ref cdc_thru [get_files cdc_thru.xdc]
set_property scoped_to_ref pulse_bridge [get_files pulse_bridge.xdc]

#Im trying this to see
# set_property source_mgmt_mode None [current_project]
# set_property top_file util_dacfifo.v [current_fileset]

# If err msg says "cant validate top module util_dacfifo"
# that could mean theres a syntax error in HDL.

# This function calls ipx::package_project:
adi_ip_properties_lite util_dacfifo

adi_ip_ttcl util_dacfifo "util_dacfifo_ooc.ttcl"


ipx::infer_bus_interface dma_clk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface dma_rst xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface dac_clk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface dac_rst xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]

ipx::package_project -import_files "$ad_hdl_dir/library/common/util_pkg.vhd"

ipx::save_core [ipx::current_core]

