class_name BaseRouter
extends Object


static  func add_tree_node(node:Node):
	if is_instance_valid(Global.get_tree()):
		Global.get_tree().get_root().add_child(node)
		
static  func add_child_node(context:Node,node:Node):
	if is_instance_valid(context.get_tree()):
		context.add_child(node)

static func goto_load(path:String,time:int = 0):
	var node = load("res://common/gui/loading/loading.tscn").instantiate()
	node.path = path
	node.time = time
	add_tree_node(node)
	var resultNode = await node.load_complete_node
	return resultNode
