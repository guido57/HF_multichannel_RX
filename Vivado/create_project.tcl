# Source with: vivado -mode batch -source create_project.tcl
set root [file normalize [file dirname [info script]]]
create_project sine_dds_project "$root/vivado_project" -part xc7z020clg484-2 -force
add_files "$root/rtl/sine_dds.sv"
add_files "$root/rtl/sine_lut.mem"
set_property top sine_dds [current_fileset]
update_compile_order -fileset sources_1

# Give the GUI the same driven behavioral simulation used by sim/run_sim.tcl.
add_files -fileset sim_1 "$root/sim/tb_sine_dds.sv"
add_files -fileset sim_1 "$root/rtl/sine_lut.mem"
set_property top tb_sine_dds [get_filesets sim_1]
update_compile_order -fileset sim_1
close_project
puts "Project created at $root/vivado_project"
exit
