# Create the PS / FT8 RF core / AD9248-emulator integration design.
set root [file normalize [file join [file dirname [info script]] ..]]
set project "$root/build/vivado_project/ft8_virtual_rf.xpr"
open_project $project
set_property source_mgmt_mode All [current_project]
update_compile_order -fileset sources_1

set bd_name ft8_rf_bd
if {[llength [get_bd_designs -quiet $bd_name]] != 0} {
    puts "ERROR: block design '$bd_name' already exists"
    close_project
    exit 1
}
create_bd_design $bd_name

create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
set_property -dict [list CONFIG.PCW_EN_CLK0_PORT {1} CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {128.000000} CONFIG.PCW_USE_M_AXI_GP0 {0}] [get_bd_cells processing_system7_0]
create_bd_cell -type module -reference adc_input adc_input_0
create_bd_cell -type module -reference ddc_64m_to_8k ddc_channel_a_0

create_bd_cell -type hier ft8_virtual_rf_subsystem
current_bd_instance ft8_virtual_rf_subsystem

create_bd_pin -dir I -type clk clk128
create_bd_pin -dir I -type clk clka
create_bd_pin -dir I -type clk clkb
create_bd_pin -dir I start_ft8
create_bd_pin -dir I stop_ft8
create_bd_pin -dir I -from 14 -to 0 rf_freq_khz
create_bd_pin -dir I -from 236 -to 0 ft8_symbols
create_bd_pin -dir O source_active
create_bd_pin -dir O -from 13 -to 0 data
create_bd_pin -dir O otra
create_bd_pin -dir O otrb

create_bd_cell -type module -reference ft8_virtual_rf_core ft8_virtual_rf_core_0
create_bd_cell -type module -reference ad9248_emulator ad9248_emulator_0
connect_bd_net [get_bd_pins clk128] [get_bd_pins ft8_virtual_rf_core_0/clk128] [get_bd_pins ad9248_emulator_0/clk128]
connect_bd_net [get_bd_pins start_ft8] [get_bd_pins ft8_virtual_rf_core_0/start_ft8]
connect_bd_net [get_bd_pins stop_ft8] [get_bd_pins ft8_virtual_rf_core_0/stop_ft8]
connect_bd_net [get_bd_pins rf_freq_khz] [get_bd_pins ft8_virtual_rf_core_0/rf_freq_khz]
connect_bd_net [get_bd_pins ft8_symbols] [get_bd_pins ft8_virtual_rf_core_0/ft8_symbols]
connect_bd_net [get_bd_pins ft8_virtual_rf_core_0/source_active] [get_bd_pins source_active]
connect_bd_net [get_bd_pins ft8_virtual_rf_core_0/sample_a] [get_bd_pins ad9248_emulator_0/sample_a]
connect_bd_net [get_bd_pins ft8_virtual_rf_core_0/sample_b] [get_bd_pins ad9248_emulator_0/sample_b]
connect_bd_net [get_bd_pins clka] [get_bd_pins ad9248_emulator_0/clka]
connect_bd_net [get_bd_pins clkb] [get_bd_pins ad9248_emulator_0/clkb]
foreach pin {data otra otrb} {
    connect_bd_net [get_bd_pins ad9248_emulator_0/$pin] [get_bd_pins $pin]
}

current_bd_instance /
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins ft8_virtual_rf_subsystem/clk128]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins adc_input_0/clk128]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins ddc_channel_a_0/clk128]
connect_bd_net [get_bd_pins adc_input_0/clka] [get_bd_pins ft8_virtual_rf_subsystem/clka]
connect_bd_net [get_bd_pins adc_input_0/clkb] [get_bd_pins ft8_virtual_rf_subsystem/clkb]
connect_bd_net [get_bd_pins ft8_virtual_rf_subsystem/data] [get_bd_pins adc_input_0/virtual_data]
connect_bd_net [get_bd_pins ft8_virtual_rf_subsystem/otra] [get_bd_pins adc_input_0/virtual_otra]
connect_bd_net [get_bd_pins ft8_virtual_rf_subsystem/otrb] [get_bd_pins adc_input_0/virtual_otrb]
connect_bd_net [get_bd_pins adc_input_0/ddc_sample_a] [get_bd_pins ddc_channel_a_0/sample_in]
connect_bd_net [get_bd_pins adc_input_0/ddc_valid_a] [get_bd_pins ddc_channel_a_0/sample_valid]
foreach pin {source_active} {
    make_bd_pins_external [get_bd_pins ft8_virtual_rf_subsystem/$pin]
}
foreach pin {adc_data adc_otra adc_otrb clka clkb ddc_sample_a ddc_sample_b ddc_valid_a ddc_valid_b} {
    make_bd_pins_external [get_bd_pins adc_input_0/$pin]
}
foreach pin {i_out q_out output_valid} {
    make_bd_pins_external [get_bd_pins ddc_channel_a_0/$pin]
}

# Fixed first-simulation preset: virtual FT8 source at 14.075 MHz.
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 select_virtual_0
set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {1}] [get_bd_cells select_virtual_0]
connect_bd_net [get_bd_pins select_virtual_0/dout] [get_bd_pins adc_input_0/select_virtual]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 rf_freq_khz_0
set_property -dict [list CONFIG.CONST_WIDTH {15} CONFIG.CONST_VAL {14075}] [get_bd_cells rf_freq_khz_0]
connect_bd_net [get_bd_pins rf_freq_khz_0/dout] [get_bd_pins ft8_virtual_rf_subsystem/rf_freq_khz]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 start_ft8_0
set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {1}] [get_bd_cells start_ft8_0]
connect_bd_net [get_bd_pins start_ft8_0/dout] [get_bd_pins ft8_virtual_rf_subsystem/start_ft8]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 stop_ft8_0
set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {0}] [get_bd_cells stop_ft8_0]
connect_bd_net [get_bd_pins stop_ft8_0/dout] [get_bd_pins ft8_virtual_rf_subsystem/stop_ft8]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 ft8_symbols_k1abc_0
set_property -dict [list CONFIG.CONST_WIDTH {237} CONFIG.CONST_VAL {75084642826647063703584787342781992170070057832874459365619116406399243}] [get_bd_cells ft8_symbols_k1abc_0]
connect_bd_net [get_bd_pins ft8_symbols_k1abc_0/dout] [get_bd_pins ft8_virtual_rf_subsystem/ft8_symbols]

# First DDC preset: tune to the virtual source's 14.075 MHz base carrier.
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 ddc_vfo_hz_0
set_property -dict [list CONFIG.CONST_WIDTH {25} CONFIG.CONST_VAL {14075000}] [get_bd_cells ddc_vfo_hz_0]
connect_bd_net [get_bd_pins ddc_vfo_hz_0/dout] [get_bd_pins ddc_channel_a_0/vfo_hz]
make_bd_intf_pins_external [get_bd_intf_pins processing_system7_0/DDR]
make_bd_intf_pins_external [get_bd_intf_pins processing_system7_0/FIXED_IO]

save_bd_design
set_property USED_IN_SIMULATION false [get_files "$root/build/vivado_project/ft8_virtual_rf.srcs/sources_1/bd/$bd_name/$bd_name.bd"]
generate_target all [get_files "$root/build/vivado_project/ft8_virtual_rf.srcs/sources_1/bd/$bd_name/$bd_name.bd"]
make_wrapper -files [get_files "$root/build/vivado_project/ft8_virtual_rf.srcs/sources_1/bd/$bd_name/$bd_name.bd"] -top
add_files -norecurse "$root/build/vivado_project/ft8_virtual_rf.gen/sources_1/bd/$bd_name/hdl/${bd_name}_wrapper.v"
set_property USED_IN_SIMULATION false [get_files "$root/build/vivado_project/ft8_virtual_rf.gen/sources_1/bd/$bd_name/hdl/${bd_name}_wrapper.v"]
set_property top ${bd_name}_wrapper [get_filesets sources_1]
update_compile_order -fileset sources_1
close_project
puts "Created block design '$bd_name'."
source "$root/scripts/integrate_axi_control.tcl"
