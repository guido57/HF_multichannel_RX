set root [file normalize [file join [file dirname [info script]] ..]]
open_project "$root/build/vivado_project/ft8_virtual_rf.xpr"
reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1
set status [get_property STATUS [get_runs synth_1]]
puts "SYNTHESIS_STATUS: $status"
if {![string match "synth_design Complete*" $status]} { exit 1 }
open_run synth_1
report_utilization -file "$root/build/axi_integrated_synthesis_utilization.rpt"
close_project
exit
