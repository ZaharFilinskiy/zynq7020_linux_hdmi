
################################################################
# This is a generated script based on design: design_1
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2018.3
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source design_1_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# axis_hdmi_source, axis_hdmi_video

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7z020clg400-2
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name design_1

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:clk_wiz:6.0\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:proc_sys_reset:5.0\
digilentinc.com:ip:rgb2dvi:1.4\
"

   set list_ips_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
axis_hdmi_source\
axis_hdmi_video\
"

   set list_mods_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_msg_id "BD_TCL-008" "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports

  # Create ports
  set hdmi_clk_50m [ create_bd_port -dir I -type clk hdmi_clk_50m ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {50000000} \
 ] $hdmi_clk_50m
  set hdmi_out_en [ create_bd_port -dir O -from 0 -to 0 hdmi_out_en ]
  set hdmi_reset_n [ create_bd_port -dir I -type rst hdmi_reset_n ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $hdmi_reset_n
  set hdmi_tx_clk_n [ create_bd_port -dir O hdmi_tx_clk_n ]
  set hdmi_tx_clk_p [ create_bd_port -dir O hdmi_tx_clk_p ]
  set hdmi_tx_data_n [ create_bd_port -dir O -from 2 -to 0 hdmi_tx_data_n ]
  set hdmi_tx_data_p [ create_bd_port -dir O -from 2 -to 0 hdmi_tx_data_p ]

  # Create instance: hdmi_clocks, and set properties
  set hdmi_clocks [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 hdmi_clocks ]
  set_property -dict [ list \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {74.2} \
   CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {371.25} \
   CONFIG.CLKOUT2_USED {true} \
   CONFIG.PRIM_IN_FREQ {50.000} \
   CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
   CONFIG.RESET_TYPE {ACTIVE_LOW} \
 ] $hdmi_clocks

  # Create instance: hdmi_enable, and set properties
  set hdmi_enable [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 hdmi_enable ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {1} \
   CONFIG.CONST_WIDTH {1} \
 ] $hdmi_enable

  # Create instance: hdmi_low, and set properties
  set hdmi_low [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 hdmi_low ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {1} \
 ] $hdmi_low

  # Create instance: hdmi_pixel_reset, and set properties
  set hdmi_pixel_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 hdmi_pixel_reset ]

  # Create instance: hdmi_source, and set properties
  set block_name axis_hdmi_source
  set block_cell_name hdmi_source
  if { [catch {set hdmi_source [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $hdmi_source eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.H_ACTIVE {1280} \
   CONFIG.TEST_PATTERN {1} \
   CONFIG.V_ACTIVE {720} \
 ] $hdmi_source

  # Create instance: hdmi_tx, and set properties
  set hdmi_tx [ create_bd_cell -type ip -vlnv digilentinc.com:ip:rgb2dvi:1.4 hdmi_tx ]
  set_property -dict [ list \
   CONFIG.kClkRange {1} \
   CONFIG.kGenerateSerialClk {false} \
   CONFIG.kRstActiveHigh {false} \
 ] $hdmi_tx

  # Create instance: hdmi_video, and set properties
  set block_name axis_hdmi_video
  set block_cell_name hdmi_video
  if { [catch {set hdmi_video [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $hdmi_video eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.H_ACTIVE {1280} \
   CONFIG.H_BP {220} \
   CONFIG.H_FP {110} \
   CONFIG.H_SYNC {40} \
   CONFIG.SYNC_POSITIVE {1} \
   CONFIG.V_ACTIVE {720} \
   CONFIG.V_BP {20} \
   CONFIG.V_FP {5} \
   CONFIG.V_SYNC {5} \
 ] $hdmi_video

  # Create instance: hdmi_zero_data, and set properties
  set hdmi_zero_data [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 hdmi_zero_data ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {32} \
 ] $hdmi_zero_data

  # Create interface connections
  connect_bd_intf_net -intf_net hdmi_source_M_AXIS [get_bd_intf_pins hdmi_source/M_AXIS] [get_bd_intf_pins hdmi_video/S_AXIS]

  # Create port connections
  connect_bd_net -net hdmi_clk_50m_1 [get_bd_ports hdmi_clk_50m] [get_bd_pins hdmi_clocks/clk_in1]
  connect_bd_net -net hdmi_clocks_clk_out1 [get_bd_pins hdmi_clocks/clk_out1] [get_bd_pins hdmi_pixel_reset/slowest_sync_clk] [get_bd_pins hdmi_source/pixel_clk] [get_bd_pins hdmi_tx/PixelClk] [get_bd_pins hdmi_video/pixel_clk]
  connect_bd_net -net hdmi_clocks_clk_out2 [get_bd_pins hdmi_clocks/clk_out2] [get_bd_pins hdmi_tx/SerialClk]
  connect_bd_net -net hdmi_clocks_locked [get_bd_pins hdmi_clocks/locked] [get_bd_pins hdmi_pixel_reset/dcm_locked]
  connect_bd_net -net hdmi_enable_dout [get_bd_ports hdmi_out_en] [get_bd_pins hdmi_enable/dout]
  connect_bd_net -net hdmi_low_dout [get_bd_pins hdmi_low/dout] [get_bd_pins hdmi_pixel_reset/aux_reset_in] [get_bd_pins hdmi_pixel_reset/mb_debug_sys_rst] [get_bd_pins hdmi_source/s_axis_tlast] [get_bd_pins hdmi_source/s_axis_tuser] [get_bd_pins hdmi_source/s_axis_tvalid]
  connect_bd_net -net hdmi_pixel_reset_peripheral_aresetn [get_bd_pins hdmi_pixel_reset/peripheral_aresetn] [get_bd_pins hdmi_source/resetn] [get_bd_pins hdmi_tx/aRst_n] [get_bd_pins hdmi_video/resetn]
  connect_bd_net -net hdmi_reset_n_1 [get_bd_ports hdmi_reset_n] [get_bd_pins hdmi_clocks/resetn] [get_bd_pins hdmi_pixel_reset/ext_reset_in]
  connect_bd_net -net hdmi_tx_TMDS_Clk_n [get_bd_ports hdmi_tx_clk_n] [get_bd_pins hdmi_tx/TMDS_Clk_n]
  connect_bd_net -net hdmi_tx_TMDS_Clk_p [get_bd_ports hdmi_tx_clk_p] [get_bd_pins hdmi_tx/TMDS_Clk_p]
  connect_bd_net -net hdmi_tx_TMDS_Data_n [get_bd_ports hdmi_tx_data_n] [get_bd_pins hdmi_tx/TMDS_Data_n]
  connect_bd_net -net hdmi_tx_TMDS_Data_p [get_bd_ports hdmi_tx_data_p] [get_bd_pins hdmi_tx/TMDS_Data_p]
  connect_bd_net -net hdmi_video_video_de [get_bd_pins hdmi_tx/vid_pVDE] [get_bd_pins hdmi_video/video_de]
  connect_bd_net -net hdmi_video_video_hsync [get_bd_pins hdmi_tx/vid_pHSync] [get_bd_pins hdmi_video/video_hsync]
  connect_bd_net -net hdmi_video_video_rbg [get_bd_pins hdmi_tx/vid_pData] [get_bd_pins hdmi_video/video_rbg]
  connect_bd_net -net hdmi_video_video_vsync [get_bd_pins hdmi_tx/vid_pVSync] [get_bd_pins hdmi_video/video_vsync]
  connect_bd_net -net hdmi_zero_data_dout [get_bd_pins hdmi_source/s_axis_tdata] [get_bd_pins hdmi_zero_data/dout]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


