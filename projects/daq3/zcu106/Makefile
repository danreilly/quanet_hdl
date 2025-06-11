####################################################################################
## Copyright (c) 2018 - 2023 Analog Devices, Inc.
### SPDX short identifier: BSD-1-Clause
## Auto-generated, do not modify!
####################################################################################

PROJECT_NAME := daq3_zcu106

M_DEPS += ../common/daq3_spi.v
M_DEPS += ../common/daq3_bd.tcl
M_DEPS += ../../scripts/adi_pd.tcl
M_DEPS += ../../common/zcu106/zcu106_system_constr.xdc
M_DEPS += ../../common/zcu106/zcu106_system_bd.tcl
M_DEPS += ../../common/zcu106/zcu106_plddr4_adcfifo_bd.tcl
M_DEPS += ../../common/xilinx/dacfifo_bd.tcl
M_DEPS += ../../../library/jesd204/scripts/jesd204.tcl
M_DEPS += ../../../library/common/ad_iobuf.v
M_DEPS += happycamper/my_gth_wrap.vhd
M_DEPS += happycamper/gth_driver.vhd

# This should really be called IP_DEPS.
# This is the list of IPs that must be "made" before
# the top level system_top.v gets synthesized.
# LIB_DEPS += quanet_regs
LIB_DEPS += quanet_sfp
LIB_DEPS += axi_clkgen
LIB_DEPS += axi_dmac
LIB_DEPS += axi_hdmi_tx
LIB_DEPS += axi_spdif_tx
LIB_DEPS += axi_sysid
# LIB_DEPS += quanet_regs
LIB_DEPS += jesd204/ad_ip_jesd204_tpl_adc
LIB_DEPS += jesd204/ad_ip_jesd204_tpl_dac
LIB_DEPS += jesd204/axi_jesd204_rx
LIB_DEPS += jesd204/axi_jesd204_tx
LIB_DEPS += jesd204/jesd204_rx
LIB_DEPS += jesd204/jesd204_tx
LIB_DEPS += sysid_rom
# LIB_DEPS += util_dacfifo
LIB_DEPS += util_pack/util_cpack2
LIB_DEPS += util_pack/util_upack2
#LIB_DEPS += xilinx/axi_adcfifo
LIB_DEPS += quanet_adc
LIB_DEPS += quanet_dac
LIB_DEPS += xilinx/axi_adxcvr
LIB_DEPS += xilinx/util_adxcvr

include ../../scripts/project-xilinx.mk
