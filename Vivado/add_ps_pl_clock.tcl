# Replaces the external DDS clock/reset with Zynq PS FCLK_CLK0/FCLK_RESET0_N.
# Run only while the Vivado project is closed.
set root [file normalize [file dirname [info script]]]
set project "$root/vivado_project/sine_dds_project.xpr"
set bd_file "$root/vivado_project/sine_dds_project.srcs/sources_1/bd/sine_dds_bd/sine_dds_bd.bd"

open_project $project
open_bd_design $bd_file

if {[llength [get_bd_cells -quiet processing_system7_0]] == 0} {
  create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
}

# The PS generates a 100 MHz clock for programmable logic on FCLK_CLK0.
set_property -dict [list \
  CONFIG.PCW_EN_CLK0_PORT {1} \
  CONFIG.PCW_USE_M_AXI_GP0 {0} \
  CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100.000000}] \
  [get_bd_cells processing_system7_0]

# Remove the former external clock/reset net connections, then use PS fabric signals.
foreach port_name {clk rst_n} pin_name {clk rst_n} {
  set pin [get_bd_pins sine_dds_0/$pin_name]
  set net [get_bd_nets -quiet -of_objects $pin]
  if {[llength $net] != 0} {
    disconnect_bd_net $net $pin
    if {[llength [get_bd_pins -quiet -of_objects $net]] == 0} { delete_bd_objs $net }
  }
  set port [get_bd_ports -quiet $port_name]
  if {[llength $port] != 0} { delete_bd_objs $port }
}
# Vivado can retain these named, source-less nets after deleting external ports.
foreach orphan_net {clk_1 rst_n_1} {
  set net [get_bd_nets -quiet $orphan_net]
  if {[llength $net] != 0} { delete_bd_objs $net }
}
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins sine_dds_0/clk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins sine_dds_0/rst_n]

# The module now offers a cosine channel too; make it visible at the BD boundary.
if {[llength [get_bd_ports -quiet cosine_out]] == 0} {
  create_bd_port -dir O -from 15 -to 0 cosine_out
}
if {[llength [get_bd_nets -quiet -of_objects [get_bd_pins sine_dds_0/cosine_out]]] == 0} {
  connect_bd_net [get_bd_ports cosine_out] [get_bd_pins sine_dds_0/cosine_out]
}

# These are the physical Zynq processing-system interfaces, to be constrained for a board later.
if {[llength [get_bd_intf_ports -quiet DDR]] == 0} {
  make_bd_intf_pins_external [get_bd_intf_pins processing_system7_0/DDR]
}
if {[llength [get_bd_intf_ports -quiet FIXED_IO]] == 0} {
  make_bd_intf_pins_external [get_bd_intf_pins processing_system7_0/FIXED_IO]
}

save_bd_design
generate_target all [get_files $bd_file]
update_compile_order -fileset sources_1
close_project
puts "Connected sine_dds_0 to processing_system7_0 FCLK_CLK0 (100 MHz)."
exit
