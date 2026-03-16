# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0" -display_name {AXIS Config}]
  ipgui::add_param $IPINST -name "C_S00_AXI_DATA_WIDTH" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_S00_AXI_ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_HIGHADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_M00_AXIS_TDATA_WIDTH" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_M00_AXIS_START_COUNT" -parent ${Page_0}

  #Adding Page
  set ADC_Controller_Config [ipgui::add_page $IPINST -name "ADC Controller Config"]
  ipgui::add_param $IPINST -name "USR_CLK_CYCLE_NS" -parent ${ADC_Controller_Config}
  ipgui::add_param $IPINST -name "T_CYCLE_NS" -parent ${ADC_Controller_Config}
  ipgui::add_param $IPINST -name "T_RESET_NS" -parent ${ADC_Controller_Config}
  ipgui::add_param $IPINST -name "T26_NS" -parent ${ADC_Controller_Config}
  ipgui::add_param $IPINST -name "T15_NS" -parent ${ADC_Controller_Config}
  ipgui::add_param $IPINST -name "T14_NS" -parent ${ADC_Controller_Config}
  ipgui::add_param $IPINST -name "T11_NS" -parent ${ADC_Controller_Config}
  ipgui::add_param $IPINST -name "T10_NS" -parent ${ADC_Controller_Config}
  ipgui::add_param $IPINST -name "T2_NS" -parent ${ADC_Controller_Config}
  ipgui::add_param $IPINST -name "T1_NS" -parent ${ADC_Controller_Config}
  ipgui::add_param $IPINST -name "T_CONV_MAX_NS" -parent ${ADC_Controller_Config}
  ipgui::add_param $IPINST -name "T_CONV_MIN_NS" -parent ${ADC_Controller_Config}
  ipgui::add_param $IPINST -name "C_M_AXIS_BUFFER_SIZE" -parent ${ADC_Controller_Config}
  ipgui::add_param $IPINST -name "FRAME_HEADER" -parent ${ADC_Controller_Config} -widget comboBox
  ipgui::add_param $IPINST -name "FRAME_TAILER" -parent ${ADC_Controller_Config} -widget comboBox


}

proc update_PARAM_VALUE.C_M_AXIS_BUFFER_SIZE { PARAM_VALUE.C_M_AXIS_BUFFER_SIZE } {
	# Procedure called to update C_M_AXIS_BUFFER_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXIS_BUFFER_SIZE { PARAM_VALUE.C_M_AXIS_BUFFER_SIZE } {
	# Procedure called to validate C_M_AXIS_BUFFER_SIZE
	return true
}

proc update_PARAM_VALUE.FRAME_HEADER { PARAM_VALUE.FRAME_HEADER } {
	# Procedure called to update FRAME_HEADER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FRAME_HEADER { PARAM_VALUE.FRAME_HEADER } {
	# Procedure called to validate FRAME_HEADER
	return true
}

proc update_PARAM_VALUE.FRAME_TAILER { PARAM_VALUE.FRAME_TAILER } {
	# Procedure called to update FRAME_TAILER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FRAME_TAILER { PARAM_VALUE.FRAME_TAILER } {
	# Procedure called to validate FRAME_TAILER
	return true
}

proc update_PARAM_VALUE.T10_NS { PARAM_VALUE.T10_NS } {
	# Procedure called to update T10_NS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.T10_NS { PARAM_VALUE.T10_NS } {
	# Procedure called to validate T10_NS
	return true
}

proc update_PARAM_VALUE.T11_NS { PARAM_VALUE.T11_NS } {
	# Procedure called to update T11_NS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.T11_NS { PARAM_VALUE.T11_NS } {
	# Procedure called to validate T11_NS
	return true
}

proc update_PARAM_VALUE.T14_NS { PARAM_VALUE.T14_NS } {
	# Procedure called to update T14_NS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.T14_NS { PARAM_VALUE.T14_NS } {
	# Procedure called to validate T14_NS
	return true
}

proc update_PARAM_VALUE.T15_NS { PARAM_VALUE.T15_NS } {
	# Procedure called to update T15_NS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.T15_NS { PARAM_VALUE.T15_NS } {
	# Procedure called to validate T15_NS
	return true
}

proc update_PARAM_VALUE.T1_NS { PARAM_VALUE.T1_NS } {
	# Procedure called to update T1_NS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.T1_NS { PARAM_VALUE.T1_NS } {
	# Procedure called to validate T1_NS
	return true
}

proc update_PARAM_VALUE.T26_NS { PARAM_VALUE.T26_NS } {
	# Procedure called to update T26_NS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.T26_NS { PARAM_VALUE.T26_NS } {
	# Procedure called to validate T26_NS
	return true
}

proc update_PARAM_VALUE.T2_NS { PARAM_VALUE.T2_NS } {
	# Procedure called to update T2_NS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.T2_NS { PARAM_VALUE.T2_NS } {
	# Procedure called to validate T2_NS
	return true
}

proc update_PARAM_VALUE.T_CONV_MAX_NS { PARAM_VALUE.T_CONV_MAX_NS } {
	# Procedure called to update T_CONV_MAX_NS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.T_CONV_MAX_NS { PARAM_VALUE.T_CONV_MAX_NS } {
	# Procedure called to validate T_CONV_MAX_NS
	return true
}

proc update_PARAM_VALUE.T_CONV_MIN_NS { PARAM_VALUE.T_CONV_MIN_NS } {
	# Procedure called to update T_CONV_MIN_NS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.T_CONV_MIN_NS { PARAM_VALUE.T_CONV_MIN_NS } {
	# Procedure called to validate T_CONV_MIN_NS
	return true
}

proc update_PARAM_VALUE.T_CYCLE_NS { PARAM_VALUE.T_CYCLE_NS } {
	# Procedure called to update T_CYCLE_NS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.T_CYCLE_NS { PARAM_VALUE.T_CYCLE_NS } {
	# Procedure called to validate T_CYCLE_NS
	return true
}

proc update_PARAM_VALUE.T_RESET_NS { PARAM_VALUE.T_RESET_NS } {
	# Procedure called to update T_RESET_NS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.T_RESET_NS { PARAM_VALUE.T_RESET_NS } {
	# Procedure called to validate T_RESET_NS
	return true
}

proc update_PARAM_VALUE.USR_CLK_CYCLE_NS { PARAM_VALUE.USR_CLK_CYCLE_NS } {
	# Procedure called to update USR_CLK_CYCLE_NS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.USR_CLK_CYCLE_NS { PARAM_VALUE.USR_CLK_CYCLE_NS } {
	# Procedure called to validate USR_CLK_CYCLE_NS
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to update C_S00_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S00_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S00_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S00_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to update C_S00_AXI_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to validate C_S00_AXI_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to update C_S00_AXI_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to validate C_S00_AXI_HIGHADDR
	return true
}

proc update_PARAM_VALUE.C_M00_AXIS_TDATA_WIDTH { PARAM_VALUE.C_M00_AXIS_TDATA_WIDTH } {
	# Procedure called to update C_M00_AXIS_TDATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M00_AXIS_TDATA_WIDTH { PARAM_VALUE.C_M00_AXIS_TDATA_WIDTH } {
	# Procedure called to validate C_M00_AXIS_TDATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M00_AXIS_START_COUNT { PARAM_VALUE.C_M00_AXIS_START_COUNT } {
	# Procedure called to update C_M00_AXIS_START_COUNT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M00_AXIS_START_COUNT { PARAM_VALUE.C_M00_AXIS_START_COUNT } {
	# Procedure called to validate C_M00_AXIS_START_COUNT
	return true
}


proc update_MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M00_AXIS_TDATA_WIDTH { MODELPARAM_VALUE.C_M00_AXIS_TDATA_WIDTH PARAM_VALUE.C_M00_AXIS_TDATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M00_AXIS_TDATA_WIDTH}] ${MODELPARAM_VALUE.C_M00_AXIS_TDATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M00_AXIS_START_COUNT { MODELPARAM_VALUE.C_M00_AXIS_START_COUNT PARAM_VALUE.C_M00_AXIS_START_COUNT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M00_AXIS_START_COUNT}] ${MODELPARAM_VALUE.C_M00_AXIS_START_COUNT}
}

proc update_MODELPARAM_VALUE.USR_CLK_CYCLE_NS { MODELPARAM_VALUE.USR_CLK_CYCLE_NS PARAM_VALUE.USR_CLK_CYCLE_NS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.USR_CLK_CYCLE_NS}] ${MODELPARAM_VALUE.USR_CLK_CYCLE_NS}
}

proc update_MODELPARAM_VALUE.T_CYCLE_NS { MODELPARAM_VALUE.T_CYCLE_NS PARAM_VALUE.T_CYCLE_NS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.T_CYCLE_NS}] ${MODELPARAM_VALUE.T_CYCLE_NS}
}

proc update_MODELPARAM_VALUE.T_RESET_NS { MODELPARAM_VALUE.T_RESET_NS PARAM_VALUE.T_RESET_NS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.T_RESET_NS}] ${MODELPARAM_VALUE.T_RESET_NS}
}

proc update_MODELPARAM_VALUE.T_CONV_MIN_NS { MODELPARAM_VALUE.T_CONV_MIN_NS PARAM_VALUE.T_CONV_MIN_NS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.T_CONV_MIN_NS}] ${MODELPARAM_VALUE.T_CONV_MIN_NS}
}

proc update_MODELPARAM_VALUE.T_CONV_MAX_NS { MODELPARAM_VALUE.T_CONV_MAX_NS PARAM_VALUE.T_CONV_MAX_NS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.T_CONV_MAX_NS}] ${MODELPARAM_VALUE.T_CONV_MAX_NS}
}

proc update_MODELPARAM_VALUE.T1_NS { MODELPARAM_VALUE.T1_NS PARAM_VALUE.T1_NS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.T1_NS}] ${MODELPARAM_VALUE.T1_NS}
}

proc update_MODELPARAM_VALUE.T2_NS { MODELPARAM_VALUE.T2_NS PARAM_VALUE.T2_NS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.T2_NS}] ${MODELPARAM_VALUE.T2_NS}
}

proc update_MODELPARAM_VALUE.T10_NS { MODELPARAM_VALUE.T10_NS PARAM_VALUE.T10_NS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.T10_NS}] ${MODELPARAM_VALUE.T10_NS}
}

proc update_MODELPARAM_VALUE.T11_NS { MODELPARAM_VALUE.T11_NS PARAM_VALUE.T11_NS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.T11_NS}] ${MODELPARAM_VALUE.T11_NS}
}

proc update_MODELPARAM_VALUE.T14_NS { MODELPARAM_VALUE.T14_NS PARAM_VALUE.T14_NS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.T14_NS}] ${MODELPARAM_VALUE.T14_NS}
}

proc update_MODELPARAM_VALUE.T15_NS { MODELPARAM_VALUE.T15_NS PARAM_VALUE.T15_NS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.T15_NS}] ${MODELPARAM_VALUE.T15_NS}
}

proc update_MODELPARAM_VALUE.T26_NS { MODELPARAM_VALUE.T26_NS PARAM_VALUE.T26_NS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.T26_NS}] ${MODELPARAM_VALUE.T26_NS}
}

proc update_MODELPARAM_VALUE.C_M_AXIS_BUFFER_SIZE { MODELPARAM_VALUE.C_M_AXIS_BUFFER_SIZE PARAM_VALUE.C_M_AXIS_BUFFER_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXIS_BUFFER_SIZE}] ${MODELPARAM_VALUE.C_M_AXIS_BUFFER_SIZE}
}

proc update_MODELPARAM_VALUE.FRAME_HEADER { MODELPARAM_VALUE.FRAME_HEADER PARAM_VALUE.FRAME_HEADER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FRAME_HEADER}] ${MODELPARAM_VALUE.FRAME_HEADER}
}

proc update_MODELPARAM_VALUE.FRAME_TAILER { MODELPARAM_VALUE.FRAME_TAILER PARAM_VALUE.FRAME_TAILER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FRAME_TAILER}] ${MODELPARAM_VALUE.FRAME_TAILER}
}

