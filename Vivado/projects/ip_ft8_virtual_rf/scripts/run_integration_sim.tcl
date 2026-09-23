set root [file normalize [file join [file dirname [info script]] ..]]
create_project xsim_ft8_ddc "$root/build/xsim_integration" -part xc7z020clg484-2 -force
add_files "$root/rtl/ft8_virtual_rf_core.sv"
add_files "$root/rtl/ad9248_emulator.sv"
add_files "$root/rtl/adc_input.sv"
add_files "[file normalize [file join $root .. ip_ddc rtl ddc_64m_to_8k.sv]]"
add_files "[file normalize [file join $root .. ip_sine_dds rtl sine_lut.mem]]"
add_files "[file normalize [file join $root .. ip_ddc rtl ddc_fir_64k.mem]]"
add_files -fileset sim_1 "$root/sim/tb_ft8_ddc_integration.sv"
add_files -fileset sim_1 "[file normalize [file join $root .. ip_sine_dds rtl sine_lut.mem]]"
add_files -fileset sim_1 "[file normalize [file join $root .. ip_ddc rtl ddc_fir_64k.mem]]"
set_property top tb_ft8_ddc_integration [get_filesets sim_1]
launch_simulation
run 3 ms
close_sim
close_project
exit
