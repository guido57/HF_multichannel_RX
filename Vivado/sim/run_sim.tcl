# Run in batch mode: vivado -mode batch -source sim/run_sim.tcl
set root [file normalize [file join [file dirname [info script]] ..]]
create_project xsim_sine_dds "$root/sim/xsim_project" -part xc7z020clg484-2 -force
add_files "$root/rtl/sine_dds.sv"
add_files -fileset sim_1 "$root/sim/tb_sine_dds.sv"
add_files -fileset sim_1 "$root/rtl/sine_lut.mem"
set_property top tb_sine_dds [get_filesets sim_1]
launch_simulation
run all
close_sim
close_project
exit
