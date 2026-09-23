set root [file normalize [file join [file dirname [info script]] ..]]
open_project "$root/build/vivado_project/ddc_64m_to_8k.xpr"
open_run synth_1
report_utilization -hierarchical -hierarchical_depth 3 \
    -file "$root/build/synthesis_hierarchical_utilization.rpt"
close_project
exit
