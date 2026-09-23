# Replace the simulation constants with the PS-controlled AXI4-Lite register bank.
set root [file normalize [file join [file dirname [info script]] ..]]
set project "$root/build/vivado_project/ft8_virtual_rf.xpr"
open_project $project

if {[llength [get_files -quiet "$root/rtl/axi_ft8_control.sv"]] == 0} {
    add_files "$root/rtl/axi_ft8_control.sv"
}
update_compile_order -fileset sources_1
open_bd_design "$root/build/vivado_project/ft8_virtual_rf.srcs/sources_1/bd/ft8_rf_bd/ft8_rf_bd.bd"

foreach cell {select_virtual_0 rf_freq_khz_0 start_ft8_0 stop_ft8_0 ft8_symbols_k1abc_0 ddc_vfo_hz_0} {
    if {[llength [get_bd_cells -quiet $cell]] != 0} {
        delete_bd_objs [get_bd_cells $cell]
    }
}

set_property CONFIG.PCW_USE_M_AXI_GP0 {1} [get_bd_cells processing_system7_0]
if {[llength [get_bd_cells -quiet axi_ft8_control_0]] == 0} {
    create_bd_cell -type module -reference axi_ft8_control axi_ft8_control_0
}

connect_bd_net [get_bd_pins axi_ft8_control_0/select_virtual] [get_bd_pins adc_input_0/select_virtual]
connect_bd_net [get_bd_pins axi_ft8_control_0/rf_freq_khz] [get_bd_pins ft8_virtual_rf_subsystem/rf_freq_khz]
connect_bd_net [get_bd_pins axi_ft8_control_0/start_ft8] [get_bd_pins ft8_virtual_rf_subsystem/start_ft8]
connect_bd_net [get_bd_pins axi_ft8_control_0/stop_ft8] [get_bd_pins ft8_virtual_rf_subsystem/stop_ft8]
connect_bd_net [get_bd_pins axi_ft8_control_0/ft8_symbols] [get_bd_pins ft8_virtual_rf_subsystem/ft8_symbols]
connect_bd_net [get_bd_pins axi_ft8_control_0/vfo_hz] [get_bd_pins ddc_channel_a_0/vfo_hz]
connect_bd_net [get_bd_pins ft8_virtual_rf_subsystem/source_active] [get_bd_pins axi_ft8_control_0/source_active]

# Reserved status bits are zero until the remaining counters/flags are implemented.
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 status_flags_0
set_property -dict [list CONFIG.CONST_WIDTH {32} CONFIG.CONST_VAL {0}] [get_bd_cells status_flags_0]
connect_bd_net [get_bd_pins status_flags_0/dout] [get_bd_pins axi_ft8_control_0/status_flags]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} intc_ip {New AXI Interconnect}} \
    [get_bd_intf_pins axi_ft8_control_0/S_AXI]
assign_bd_address

validate_bd_design
save_bd_design
generate_target all [get_files "$root/build/vivado_project/ft8_virtual_rf.srcs/sources_1/bd/ft8_rf_bd/ft8_rf_bd.bd"]
close_project
puts "Integrated axi_ft8_control and assigned its AXI address."
exit
