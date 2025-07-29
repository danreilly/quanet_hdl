###############################################################################
## Copyright (C) 2014-2023 Analog Devices, Inc. All rights reserved.
### SPDX short identifier: ADIBSD
###############################################################################

# ip
source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip_xilinx.tcl

adi_ip_create quanet_adc
adi_ip_files quanet_adc [list \
  "$ad_hdl_dir/library/common/ad_mem.v" \
  "$ad_hdl_dir/library/common/ad_mem_asym.v" \
  "$ad_hdl_dir/library/common/up_xfer_status.v" \
  "$ad_hdl_dir/library/common/ad_axis_inf_rx.v" \
  "$ad_hdl_dir/library/quanet/global_pkg.vhd" \
  "$ad_hdl_dir/library/quanet/event_mon.vhd" \
  "$ad_hdl_dir/library/quanet/event_ctr.vhd" \
  "$ad_hdl_dir/library/quanet/event_ctr_periodic.vhd" \
  "$ad_hdl_dir/library/quanet/timekeeper.vhd" \
  "$ad_hdl_dir/library/quanet/cdc_pulse.vhd" \
  "$ad_hdl_dir/library/quanet/cdc_pulse.xdc" \
  "$ad_hdl_dir/library/quanet/cdc_sync_cross.vhd" \
  "$ad_hdl_dir/library/quanet/cdc_sync_cross.xdc" \
  "$ad_hdl_dir/library/quanet/cdc_samp.vhd" \
  "$ad_hdl_dir/library/quanet/cdc_samp.xdc" \
  "$ad_hdl_dir/library/quanet/cdc_thru.vhd" \
  "$ad_hdl_dir/library/quanet/cdc_thru.xdc" \
  "$ad_hdl_dir/library/quanet/util_pkg.vhd" \
  "$ad_hdl_dir/library/quanet/axi_reg_array.vhd" \
  "$ad_hdl_dir/library/quanet/lfsr_w.vhd" \
  "$ad_hdl_dir/library/quanet/uram_infer.vhd" \
  "$ad_hdl_dir/library/quanet/fifo_2clks_infer.vhd" \
  "$ad_hdl_dir/library/quanet/gen_hdr.vhd" \
  "$ad_hdl_dir/library/quanet/duration_ctr.vhd" \
  "$ad_hdl_dir/library/quanet/duration_upctr.vhd" \
  "$ad_hdl_dir/library/quanet/symbol_reader.vhd" \
  "rebalancer_quad.vhd" \
  "rebalancer.vhd" \
  "phase_est.vhd" \
  "decipher.vhd" \
  "div.vhd" \
  "rom_inf.vhd" \
  "rotate_iq.vhd" \
  "synchronizer.vhd" \
  "imbal_mult/imbal_mult.xci" \
  "pwr_det.vhd" \
  "period_timer.vhd" \
  "hdr_corr.vhd" \
  "hdr_corr_slice.vhd" \
  "axi_adcfifo_adc.v" \
  "axi_adcfifo_dma.v" \
  "axi_adcfifo_wr.v" \
  "axi_adcfifo_rd.v" \
  "quanet_adc.vhd" \
  "quanet_adc_constr.xdc" ]

#  "$ad_hdl_dir/library/quanet/axi_regs.vhd" \


# CDC constriants are made by instantiating these modules:
set_property scoped_to_ref cdc_thru       [get_files cdc_thru.xdc]
set_property scoped_to_ref cdc_samp       [get_files cdc_samp.xdc]
set_property scoped_to_ref cdc_sync_cross [get_files cdc_sync_cross.xdc]
set_property scoped_to_ref cdc_pulse      [get_files cdc_pulse.xdc]

# adi_ip_properties_lite axi_adcfifo
adi_ip_properties quanet_adc

if {0} {
ipx::infer_bus_interface { \
    s_axi_awaddr  s_axi_awvalid  s_axi_awready      \
    s_axi_wdata   s_axi_wvalid   s_axi_wstrb      s_axi_wready     s_axi_awprot  \
    s_axi_bresp   s_axi_bvalid   s_axi_bready \
    s_axi_araddr  s_axi_arprot   s_axi_arvalid    s_axi_arready \
    s_axi_rdata   s_axi_rresp    s_axi_rvalid    s_axi_rready } \
  xilinx.com:interface:aximm_rtl:1.0 [ipx::current_core]
  puts "iface is -> [ipx::get_bus_interfaces s_axi] <-"
  ipx::infer_bus_interface s_axi_aresetn xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]
  ipx::infer_bus_interface s_axi_aclk    xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]

  # You would think that ASSOCIATED_BUSIF would be a parameter,
  # but at this point it seems more abstract, or dereferenced than that.
  # This sets the "value" parameter of an object "bus_parameter component_1 s_axi_aclk ASSOCIATED_BUSIF"
  #puts "object is [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces s_axi_aclk -of_objects [ipx::current_core]]]"
  set_property value s_axi [ipx::get_bus_parameters ASSOCIATED_BUSIF \
				-of_objects [ipx::get_bus_interfaces s_axi_aclk -of_objects [ipx::current_core]]]

}




ipx::infer_bus_interface {\
  axi_awvalid   axi_awid   axi_awburst   axi_awlock   axi_awcache \
  axi_awprot    axi_awqos  axi_awuser    axi_awlen    axi_awsize \
  axi_awaddr    axi_awready   axi_wvalid   axi_wdata   axi_wstrb \
  axi_wlast    axi_wuser   axi_wready   axi_bvalid   axi_bid \
  axi_bresp   axi_buser   axi_bready   axi_arvalid   axi_arid \
  axi_arburst   axi_arlock   axi_arcache   axi_arprot   axi_arqos \
  axi_aruser   axi_arlen   axi_arsize   axi_araddr   axi_arready \
  axi_rvalid   axi_rid   axi_ruser   axi_rresp   axi_rlast \
  axi_rdata   axi_rready} \
xilinx.com:interface:aximm_rtl:1.0 [ipx::current_core]

puts "iface is -> [ipx::get_bus_interfaces axi] <-"

ipx::infer_bus_interface axi_clk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface axi_resetn xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces axi_clk \
  -of_objects [ipx::current_core]]
set_property value axi [ipx::get_bus_parameters ASSOCIATED_BUSIF \
  -of_objects [ipx::get_bus_interfaces axi_clk \
  -of_objects [ipx::current_core]]]

ipx::add_address_space axi [ipx::current_core]
set_property master_address_space_ref axi [ipx::get_bus_interfaces axi \
  -of_objects [ipx::current_core]]
set_property range 4294967296 [ipx::get_address_spaces axi \
  -of_objects [ipx::current_core]]
set_property width 512 [ipx::get_address_spaces axi \
  -of_objects [ipx::current_core]]

ipx::infer_bus_interface dma_clk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface adc_clk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface adc_rst xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]

ipx::save_core [ipx::current_core]

