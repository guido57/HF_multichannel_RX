# Adds a block design around the sine DDS.
# Run only while the Vivado project is closed:
#   vivado -mode batch -source create_block_design.tcl
set root [file normalize [file dirname [info script]]]
open_project "$root/vivado_project/sine_dds_project.xpr"

set bd_name sine_dds_bd
if {[llength [get_bd_designs -quiet $bd_name]] != 0} {
  puts "ERROR: Block design '$bd_name' already exists; no changes made."
  close_project
  exit 1
}

create_bd_design $bd_name

# External fabric-clock, active-low reset, and 16-bit two's-complement sample.
set clk_port [create_bd_port -dir I -type clk clk]
set_property CONFIG.FREQ_HZ 100000000 $clk_port
set rst_port [create_bd_port -dir I -type rst rst_n]
set_property CONFIG.POLARITY ACTIVE_LOW $rst_port
create_bd_port -dir O -from 15 -to 0 sine_out
create_bd_port -dir O -from 15 -to 0 cosine_out

create_bd_cell -type module -reference sine_dds sine_dds_0
connect_bd_net [get_bd_ports clk] [get_bd_pins sine_dds_0/clk]
connect_bd_net [get_bd_ports rst_n] [get_bd_pins sine_dds_0/rst_n]
connect_bd_net [get_bd_ports sine_out] [get_bd_pins sine_dds_0/sine_out]
connect_bd_net [get_bd_ports cosine_out] [get_bd_pins sine_dds_0/cosine_out]

save_bd_design
generate_target all [get_files "$root/vivado_project/sine_dds_project.srcs/sources_1/bd/$bd_name/$bd_name.bd"]
make_wrapper -files [get_files "$root/vivado_project/sine_dds_project.srcs/sources_1/bd/$bd_name/$bd_name.bd"] -top
add_files -norecurse "$root/vivado_project/sine_dds_project.gen/sources_1/bd/$bd_name/hdl/${bd_name}_wrapper.v"
set_property top ${bd_name}_wrapper [get_filesets sources_1]
update_compile_order -fileset sources_1
close_project
puts "Created block design '$bd_name' and set its wrapper as the synthesis top."
exit
