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

set_param ips.enableInterfaceArrayInference false

adi_ip_create util_dacfifo
adi_ip_files util_dacfifo [list \
  "$ad_hdl_dir/library/common/ad_mem.v" \
  "$ad_hdl_dir/library/common/ad_b2g.v" \
  "$ad_hdl_dir/library/quanet/util_pkg.vhd" \
  "util_dacfifo.v" \
  "$ad_hdl_dir/library/quanet/cdc_samp.vhd" \
  "$ad_hdl_dir/library/quanet/cdc_samp.xdc" \
  "$ad_hdl_dir/library/quanet/global_pkg.vhd" \
  "$ad_hdl_dir/library/quanet/global_pkg.v" \
  "$ad_hdl_dir/library/quanet/lfsr_w.vhd" \
  "$ad_hdl_dir/library/quanet/pulse_bridge.vhd" \
  "$ad_hdl_dir/library/quanet/pulse_bridge.xdc" \
  "$ad_hdl_dir/library/quanet/axi_regs.vhd" \
  "$ad_hdl_dir/library/quanet/axi_reg_array.vhd" \
  "probe_ctl.vhd" \
  "gen_probe.vhd" \
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


# set_property scoped_to_ref cdc_thru [get_files cdc_thru.xdc]
set_property scoped_to_ref cdc_samp [get_files cdc_samp.xdc]
set_property scoped_to_ref pulse_bridge [get_files pulse_bridge.xdc]

#Im trying this to see
# set_property source_mgmt_mode None [current_project]
# set_property top_file util_dacfifo.v [current_fileset]

# If err msg says "cant validate top module util_dacfifo"
# that could mean theres a syntax error in HDL.

# This function calls ipx::package_project:
adi_ip_properties_lite util_dacfifo

puts "will infer_bus_interface"
# We had to add this after adding the slave axi interface
ipx::infer_bus_interface { \
    s_axi_awaddr  s_axi_awvalid  s_axi_awready      \
    s_axi_wdata   s_axi_wvalid   s_axi_wstrb      s_axi_wready     s_axi_awprot  \
    s_axi_bresp   s_axi_bvalid   s_axi_bready \
    s_axi_araddr  s_axi_arprot   s_axi_arvalid    s_axi_arready \
    s_axi_rdata   s_axi_rresp    s_axi_rvalid    s_axi_rready } \
  xilinx.com:interface:aximm_rtl:1.0 [ipx::current_core]

puts "iface is -> [ipx::get_bus_interfaces s_axi] <-"
# This does not work: [get_property VLNV [ipx::get_bus_interfaces s_axi]]"
# puts "vlnv is [get_property VLNV [ipx::get_bus_interfaces s_axi]]"
# puts "iface0 is [ipx::get_bus_interfaces s_axi_0]"



# dont know if I need this:
#ipx::add_memory_map s_axi [ipx::current_core]
#set_property slave_memory_map_ref s_axi [ipx::get_bus_interfaces s_axi]


ipx::infer_bus_interface dma_clk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface dma_rst xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface dac_clk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface dac_rst xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]




adi_ip_ttcl util_dacfifo "util_dacfifo_ooc.ttcl"


# Not sure how this got in here:
# ipx::package_project -import_files "$ad_hdl_dir/library/common/util_pkg.vhd"




# dont know if I need these. copied from adc_ip.tcl
ipx::infer_bus_interface s_axi_aresetn xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface s_axi_aclk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]

# You would think that ASSOCIATED_BUSIF would be a parameter,
# but at this point it seems more abstract, or dereferenced than that.
# This sets the "value" parameter of an object "bus_parameter component_1 s_axi_aclk ASSOCIATED_BUSIF"
#puts "object is [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces s_axi_aclk -of_objects [ipx::current_core]]]"
set_property value s_axi [ipx::get_bus_parameters ASSOCIATED_BUSIF \
  -of_objects [ipx::get_bus_interfaces s_axi_aclk -of_objects [ipx::current_core]]]

puts "ifaces are -> [ipx::get_bus_interfaces s_axi] <-"

if { 0 } {
    

puts "adding bus param"
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces s_axi_aclk \
  -of_objects [ipx::current_core]]
puts "setting property"


puts "how to know the VLNV of an interface?"

}

ipx::save_core [ipx::current_core]

