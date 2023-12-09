extends BaseDataControl


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func data_update():
	self.texture_normal = data.texture
	pass
