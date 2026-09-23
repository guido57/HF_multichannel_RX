set root [file normalize [file join [file dirname [info script]] ..]]
create_project xsim_axi_ft8_ddc "$root/build/xsim_axi_integration" -part xc7z020clg484-2 -force
add_files "$root/rtl/axi_ft8_control.sv"
add_files "$root/rtl/ft8_virtual_rf_core.sv"
add_files "$root/rtl/ad9248_emulator.sv"
add_files "$root/rtl/adc_input.sv"
add_files "[file normalize [file join $root .. ip_ddc rtl ddc_64m_to_8k.sv]]"
add_files "[file normalize [file join $root .. ip_sine_dds rtl sine_lut.mem]]"
add_files "[file normalize [file join $root .. ip_ddc rtl ddc_fir_64k.mem]]"
add_files -fileset sim_1 "$root/sim/tb_axi_ft8_ddc_integration.sv"
set_property top tb_axi_ft8_ddc_integration [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation
run all
close_sim
close_project
exit
