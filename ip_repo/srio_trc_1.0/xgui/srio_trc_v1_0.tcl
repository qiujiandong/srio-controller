# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  ipgui::add_param $IPINST -name "TX_ONLY" -widget comboBox
  ipgui::add_param $IPINST -name "C_DEV_ID"
  ipgui::add_param $IPINST -name "C_DEST_ID"

}

proc update_PARAM_VALUE.AXIL_AW { PARAM_VALUE.AXIL_AW } {
	# Procedure called to update AXIL_AW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXIL_AW { PARAM_VALUE.AXIL_AW } {
	# Procedure called to validate AXIL_AW
	return true
}

proc update_PARAM_VALUE.AXIL_DW { PARAM_VALUE.AXIL_DW } {
	# Procedure called to update AXIL_DW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXIL_DW { PARAM_VALUE.AXIL_DW } {
	# Procedure called to validate AXIL_DW
	return true
}

proc update_PARAM_VALUE.C_DEST_ID { PARAM_VALUE.C_DEST_ID } {
	# Procedure called to update C_DEST_ID when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_DEST_ID { PARAM_VALUE.C_DEST_ID } {
	# Procedure called to validate C_DEST_ID
	return true
}

proc update_PARAM_VALUE.C_DEV_ID { PARAM_VALUE.C_DEV_ID } {
	# Procedure called to update C_DEV_ID when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_DEV_ID { PARAM_VALUE.C_DEV_ID } {
	# Procedure called to validate C_DEV_ID
	return true
}

proc update_PARAM_VALUE.TX_ONLY { PARAM_VALUE.TX_ONLY } {
	# Procedure called to update TX_ONLY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TX_ONLY { PARAM_VALUE.TX_ONLY } {
	# Procedure called to validate TX_ONLY
	return true
}


proc update_MODELPARAM_VALUE.TX_ONLY { MODELPARAM_VALUE.TX_ONLY PARAM_VALUE.TX_ONLY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TX_ONLY}] ${MODELPARAM_VALUE.TX_ONLY}
}

proc update_MODELPARAM_VALUE.C_DEV_ID { MODELPARAM_VALUE.C_DEV_ID PARAM_VALUE.C_DEV_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_DEV_ID}] ${MODELPARAM_VALUE.C_DEV_ID}
}

proc update_MODELPARAM_VALUE.C_DEST_ID { MODELPARAM_VALUE.C_DEST_ID PARAM_VALUE.C_DEST_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_DEST_ID}] ${MODELPARAM_VALUE.C_DEST_ID}
}

proc update_MODELPARAM_VALUE.AXIL_DW { MODELPARAM_VALUE.AXIL_DW PARAM_VALUE.AXIL_DW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXIL_DW}] ${MODELPARAM_VALUE.AXIL_DW}
}

proc update_MODELPARAM_VALUE.AXIL_AW { MODELPARAM_VALUE.AXIL_AW PARAM_VALUE.AXIL_AW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXIL_AW}] ${MODELPARAM_VALUE.AXIL_AW}
}

