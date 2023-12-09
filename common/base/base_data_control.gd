@tool
class_name BaseDataControl
extends BaseControl
signal data_change
var data  = {} :
	set(value ):
		data = value
		data_update()
#		emit_signal(ModuleCommon.SIGNAL_DATA_CHANGE)
	
func data_update():

	pass
