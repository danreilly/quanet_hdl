proc build_dts {} {
    puts "running build_dts"
    hsi::open_hw_design ../daq3_zcu106.sdk/system_top.xsa
    hsi::set_repo_path ./repo
    set proc 0
    foreach procs [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR}] {
		if {[regexp {cortex} $procs]} {
			set proc $procs
			break
		}
	}
	if {$proc != 0} {
		puts "Targeting $proc"
		hsi::create_sw_design device-tree -os device_tree -proc $proc
		hsi::generate_target -dir my_dts
	} else {
		puts "Error: No processor found in XSA file"
	}
	hsi::close_hw_design [hsi::current_hw_design]
}
