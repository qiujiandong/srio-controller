# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "C_DEST_ID" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_DEV_ID" -parent ${Page_0}


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


proc update_MODELPARAM_VALUE.C_DEV_ID { MODELPARAM_VALUE.C_DEV_ID PARAM_VALUE.C_DEV_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_DEV_ID}] ${MODELPARAM_VALUE.C_DEV_ID}
}

proc update_MODELPARAM_VALUE.C_DEST_ID { MODELPARAM_VALUE.C_DEST_ID PARAM_VALUE.C_DEST_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_DEST_ID}] ${MODELPARAM_VALUE.C_DEST_ID}
}

