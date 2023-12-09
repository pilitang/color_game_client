extends Control



#
@onready var v_box_container = %VBoxContainer

#Test
# var port = 8888
# var protocol = "ws://"
# var ip = "127.0.0.1"

# Product
var port = 443
var protocol = "wss://"
# var ip = "47.89.227.219"
var ip = "121.40.151.157"


var my_peer_id = 0

var rooms = {}:
	set(value):
		rooms = value
		for node in v_box_container.get_children():
			node.queue_free()
		for key in rooms.keys():
			if not rooms[key].state: 
				var button = Button.new()
				button.text = "Room " + str(key)
				button.connect("pressed",Callable(self,"_join_room").bind(button))
				v_box_container.add_child(button)


var my_info: Dictionary = {
	"id" : 0,
	"score" : 0,
	"map_id" : null,
	"room_id" : 0
}

var is_creator: bool = false


func _join_room(node):
#	my_info[name] = $Roomid_value.text
	#multiplayer.rpc(0,GameManager,"join_room",[int(node.text),id])
	my_info["id"] = multiplayer.get_unique_id()
	GameManager.join_room.rpc_id(1, int(node.text), my_info)


# Called when the node enters the scene tree for the first time.
func _ready():
	#GameManager.client = self
	pass # Replace with function body.
	
func connected_to_server():
	print("client connected to server success!")
	$ConnStatus.text = "connected"
	#multiplayer.rpc(0,Web,"test2",["客户端向您问�?"])
	#if is_creator:
		#rpc_id(1, "create_room", my_info)
	#else:
		#rpc_id(1, "join_room", room, my_info)

func connection_failed():
	print("client connected to server failed!")
	$ConnStatus.text = "disconnected"



	#get_tree().current_scene.add_player_to_ui(info.name)


func _on_draw_map_pressed():
	var scene = load("res://node_2d.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()
	pass # Replace with function body.


func _on_create_button_pressed():
	if $ConnStatus.text == "connected":
		$StartGame.visible = false
		$Host.visible = false
		my_info["id"] = multiplayer.get_unique_id()
		GameManager.create_room.rpc_id(1, my_info)
	pass # Replace with function body.


###################################################


func _on_start_game_pressed():
	#StartGame.rpc()   #rpc func StartGame for every peer
	if $ConnStatus.text == "connected":
		$StartGame.visible = false
		$Host.visible = false
		GameManager.start_game.rpc_id(1)
	pass # Replace with function body.




func _on_connect_pressed():
	var peer = WebSocketMultiplayerPeer.new()
	var url = str(protocol) + str(ip)+":"+str(port)+"/"
	var err = peer.create_client(url)
	
	multiplayer.multiplayer_peer = peer
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.connected_to_server.connect(connected_to_server)
	my_peer_id = multiplayer.get_unique_id()
	pass # Replace with function body.
