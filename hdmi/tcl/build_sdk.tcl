# Run with C:/Xilinx/SDK/2018.3/bin/xsct.bat, after build.tcl.
# New workspace avoids mixing the old hardware export/BSP with HDMI.
set root [file normalize [file join [file dirname [info script]] ../..]]
set ws [file join $root hdmi/sdk_workspace]
setws $ws
# Import source projects when this folder was moved without Eclipse metadata.
if {[llength [getprojects]] == 0 && [file exists [file join $ws hdmi_hw/.project]]} {
 importprojects $ws
}
if {[file exists [file join $ws hdmi_hw/.project]]} {
 updatehw -hw hdmi_hw -newhwspec [file join $root hdmi/export/design_1_wrapper.hdf]
} else {
 createhw -name hdmi_hw -hwspec [file join $root hdmi/export/design_1_wrapper.hdf]
}
if {![file exists [file join $ws fsbl_hdmi/.project]]} {
 createapp -name fsbl_hdmi -hwproject hdmi_hw -proc ps7_cortexa9_0 -os standalone -lang C -app {Zynq FSBL}
}
foreach name {hdmi_display.c hdmi_display.h} {
 file copy -force [file join $root hdmi $name] [file join $ws fsbl_hdmi/src $name]
}
# Only the pre-handoff hook changes. At this stage PS/PL level shifters and
# resets have been released by the standard FSBL, unlike the earlier hook.
set hook [file join $ws fsbl_hdmi/src/fsbl_hooks.c]
set f [open $hook r]; set body [read $f]; close $f
if {[string first "HdmiDisplayInit()" $body] < 0} {
set body "#include \"hdmi_display.h\"\n#include \"xil_printf.h\"\nextern u8 BitstreamFlag;\n$body"
set marker {fsbl_printf(DEBUG_INFO,"In FsblHookBeforeHandoff function \r\n");}
if {[string first $marker $body] < 0} {error "FSBL hook template changed; inspect before patching"}
set replacement "$marker\n\t/* Video failure must not prevent serial Linux boot. */\n\tif (BitstreamFlag) {\n\t\tif (HdmiDisplayInit() != XST_SUCCESS)\n\t\t\txil_printf(\"HDMI init failed; continuing serial boot\\r\\n\");\n\t} else {\n\t\txil_printf(\"HDMI skipped: BOOT.BIN contains no bitstream\\r\\n\");\n\t}"
set body [string map [list $marker $replacement] $body]
set f [open $hook w]; puts -nonewline $f $body; close $f
}
if {![file exists [file join $ws hdmi_smoke/.project]]} {
 createapp -name hdmi_smoke -hwproject hdmi_hw -proc ps7_cortexa9_0 -os standalone -lang C -app {Empty Application}
}
file copy -force [file join $root hdmi/tests/hdmi_smoke.c] [file join $ws hdmi_smoke/src/main.c]
projects -build
file copy -force [file join $ws fsbl_hdmi/Debug/fsbl_hdmi.elf] [file join $root hdmi/export/fsbl_hdmi.elf]
file copy -force [file join $ws hdmi_smoke/Debug/hdmi_smoke.elf] [file join $root hdmi/export/hdmi_smoke.elf]
puts "HDMI FSBL built and exported"
exit
