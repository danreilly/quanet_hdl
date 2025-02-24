###############################################################################
## Copyright (C) 2014-2023 Analog Devices, Inc. All rights reserved.
### SPDX short identifier: ADIBSD
###############################################################################

# sys bram (use only when dma is not capable of keeping up).
# generic fifo interface - existence is oblivious to software.
proc ad_dacfifo_create {dac_fifo_name dac_data_width dac_dma_data_width dac_fifo_address_width} {

  if {$dac_data_width != $dac_dma_data_width} {
    return -code error [format "ERROR: util_dacfifo dac/dma widths must be the same!"]
  }
  # These are the repos:
  # REPOSITORY              string   true       c:/reilly/proj/floodlight/hdl-main/library

  puts " repo paths [get_property ip_repo_paths [current_project]]"
  set ips [get_ipdefs -all -filter "VLNV =~ *:util_dacfifo:* &&  design_tool_contexts =~ *IPI* && UPGRADE_VERSIONS == \"\""]
#  puts "ips are $ips"
  set ip [lindex $ips 0]
  puts "ip is $ip"
  report_property -all $ip
  
  # Note: ad_ip_instace is defined in $ad_hdl_dir/projects/scripts/adi_board.tcl
  ad_ip_instance util_dacfifo $dac_fifo_name
  
  puts "DBG: check for new axi iface"
  puts "ifaces are: [get_bd_intf_pins -of_objects [get_bd_cells $dac_fifo_name]]"
  
#  puts "try to add ip param"
#  puts "is [get_bd_cells $dac_fifo_name]"
#  puts "props [list_property [get_bd_cells $dac_fifo_name]]"
#  puts "vlnv [get_property VLNV [get_bd_cells $dac_fifo_name]]"
  ad_ip_parameter $dac_fifo_name CONFIG.DATA_WIDTH $dac_data_width
  ad_ip_parameter $dac_fifo_name CONFIG.ADDRESS_WIDTH $dac_fifo_address_width

}
