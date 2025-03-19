
LIBRARY_NAME := quanet_sfp

GENERIC_DEPS += ../quanet/cdc_samp.vhd
# GENERIC_DEPS += ../quanet/cdc_samp.xdc
GENERIC_DEPS += ../quanet/lfsr_w.vhd
GENERIC_DEPS += ../quanet/global_pkg.vhd
GENERIC_DEPS += ../quanet/util_pkg.vhd
GENERIC_DEPS += quanet_sfp.vhd  my_gth_wrap.vhd
GENERIC_DEPS += axi_reg_array.vhd

# these just get added to generic deps I think.
XILINX_DEPS += ../quanet/cdc_samp.xdc
XILINX_DEPS += ../quanet/cdc_pulse.xdc
XILINX_DEPS += quanet_sfp_ip.tcl
XILINX_DEPS += in_system_ibert_0/in_system_ibert_0.xci
# XILINX_DEPS += my_gth/my_gth.xci


# INTEL_DEPS += quanet_sfp_hw.tcl

include ../scripts/library.mk
