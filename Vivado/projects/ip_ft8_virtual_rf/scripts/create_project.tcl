# Create the GUI project with: vivado -mode batch -source scripts/create_project.tcl
set root [file normalize [file join [file dirname [info script]] ..]]
create_project ft8_virtual_rf "$root/build/vivado_project" -part xc7z020clg484-2 -force
set_property source_mgmt_mode None [current_project]
add_files "$root/rtl/ft8_virtual_rf.sv"
add_files "$root/rtl/ft8_virtual_rf_core.sv"
add_files "[file normalize [file join $root .. ip_sine_dds rtl sine_lut.mem]]"
add_files "$root/rtl/ad9248_emulator.sv"
add_files "$root/rtl/ad9248_clock_gen.sv"
add_files "$root/rtl/adc_input.sv"
add_files "$root/rtl/axi_ft8_control.sv"
add_files "[file normalize [file join $root .. ip_ddc rtl ddc_64m_to_8k.sv]]"
add_files "[file normalize [file join $root .. ip_ddc rtl ddc_fir_64k.mem]]"
add_files -fileset sim_1 "$root/sim/tb_ft8_virtual_rf.sv"
add_files -fileset sim_1 "$root/sim/tb_ft8_ddc_integration.sv"
add_files -fileset sim_1 "$root/sim/tb_axi_ft8_control.sv"
add_files -fileset sim_1 "$root/sim/tb_axi_ft8_ddc_integration.sv"
add_files -fileset sim_1 "$root/sim/sine_lut.mem"
add_files -fileset sim_1 "[file normalize [file join $root .. ip_ddc rtl ddc_fir_64k.mem]]"
# Use the standalone wrapper as the unambiguous staging top. The block-design
# script replaces it with ft8_rf_bd_wrapper once that wrapper exists.
set_property top ft8_virtual_rf [get_filesets sources_1]
set_property top tb_ft8_ddc_integration [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
close_project
puts "Project created at $root/build/vivado_project"
exit
