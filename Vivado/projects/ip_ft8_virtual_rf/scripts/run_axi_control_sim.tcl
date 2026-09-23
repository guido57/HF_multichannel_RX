set root [file normalize [file join [file dirname [info script]] ..]]
create_project xsim_axi_ft8_control "$root/build/xsim_axi_control" -part xc7z020clg484-2 -force
add_files "$root/rtl/axi_ft8_control.sv"
add_files -fileset sim_1 "$root/sim/tb_axi_ft8_control.sv"
set_property top tb_axi_ft8_control [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation
run all
close_sim
close_project
exit
