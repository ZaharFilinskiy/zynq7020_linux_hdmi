# Restore generated Vivado products from the tracked Block Design and RTL.
# Safe to run on a fresh Git checkout before verification/build in Vivado 2018.3.
set root [file normalize [file join [file dirname [info script]] ../..]]
open_project [file join $root zynq_linux.xpr]
set_property ip_repo_paths [list [file join $root hdmi/ip_repo]] [current_project]
update_ip_catalog
open_bd_design [file join $root zynq_linux.srcs/sources_1/bd/design_1/design_1.bd]
validate_bd_design
save_bd_design
generate_target all [get_files design_1.bd]
make_wrapper -files [get_files design_1.bd] -top
update_compile_order -fileset sources_1
close_project
puts "Git checkout prepared for Vivado"
