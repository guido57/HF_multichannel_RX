set root [file normalize [file join [file dirname [info script]] ..]]
set build_dir "$root/build/phase_input_project"

create_project ddc_phase_input $build_dir -part xc7z020clg484-2 -force
add_files "$root/rtl/ddc_64m_to_8k.sv"
add_files -fileset sources_1 "$root/rtl/ddc_fir_64k.mem"
add_files -fileset sources_1 "[file normalize [file join $root .. ip_sine_dds rtl sine_lut.mem]]"
set_property verilog_define {DDC_PHASE_INCREMENT_INPUT} [get_filesets sources_1]
set_property top ddc_64m_to_8k [get_filesets sources_1]
update_compile_order -fileset sources_1

synth_design -top ddc_64m_to_8k -part xc7z020clg484-2
report_utilization -file "$root/build/phase_input_synthesis_utilization.rpt"
exit
