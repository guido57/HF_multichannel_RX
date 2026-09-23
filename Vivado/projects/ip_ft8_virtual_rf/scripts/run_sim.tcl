# Run with: vivado -mode batch -source scripts/run_sim.tcl
set root [file normalize [file join [file dirname [info script]] ..]]
create_project xsim_ft8_virtual_rf "$root/build/xsim_project" -part xc7z020clg484-2 -force
add_files "$root/rtl/ft8_virtual_rf_core.sv"
add_files "[file normalize [file join $root .. ip_sine_dds rtl sine_lut.mem]]"
add_files -fileset sim_1 "[file normalize [file join $root .. ip_sine_dds rtl sine_lut.mem]]"
add_files -fileset sim_1 "$root/sim/tb_ft8_virtual_rf.sv"
set_property top tb_ft8_virtual_rf [get_filesets sim_1]
launch_simulation
run 30 us
close_sim
close_project
exit
