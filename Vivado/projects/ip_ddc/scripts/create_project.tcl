set root [file normalize [file join [file dirname [info script]] ..]]
create_project ddc_64m_to_8k "$root/build/vivado_project" -part xc7z020clg484-2 -force
add_files "$root/rtl/ddc_64m_to_8k.sv"
add_files "$root/rtl/ddc_fir_64k.mem"
add_files "[file normalize [file join $root .. ip_sine_dds rtl sine_lut.mem]]"
add_files -fileset sim_1 "$root/rtl/ddc_fir_64k.mem"
add_files -fileset sim_1 "[file normalize [file join $root .. ip_sine_dds rtl sine_lut.mem]]"
add_files -fileset sim_1 "$root/sim/tb_ddc_64m_to_8k.sv"
set_property top ddc_64m_to_8k [get_filesets sources_1]
set_property top tb_ddc_64m_to_8k [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
close_project
puts "Project created at $root/build/vivado_project"
exit
