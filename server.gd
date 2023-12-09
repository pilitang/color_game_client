extends Control


#var Players = {}
#var room = {}
# The port we will listen to
const PORT: int = 8000

const ERROR_INEXISTENT_ROOM: String = "There is no room with such id"
const ERROR_GAME_ALREADY_STARTED: String = "Game already started"

enum { WAITING, STARTED }

var timestamp = Time.get_datetime_string_from_system(false, true)

#var players = GameManager.Players
#var rooms = GameManager.rooms
	
func _ready():	
#	if "--server" in OS.get_cmdline_args():
	create_game()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if multiplayer.is_server():
		multiplayer.multiplayer_peer.poll()
	else:
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING || multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			multiplayer.multiplayer_peer.poll()


# 每一帧都会往客户端同步rooms信息
func _physics_process(delta):
	for key in GameManager.s_players:
		#print(GameManager.s_players_room[key].id, GameManager.s_rooms)
		#multiplayer.rpc(players_room[key].id,GameManager,"room_update",[rooms])
		GameManager._set_room_by_frame.rpc_id(GameManager.s_players[key].id, GameManager.s_rooms)

		
func create_game():
	print("func create_game entered!")
	#GameManager.server = self
	var peer = WebSocketMultiplayerPeer.new()
	
	var erro = peer.create_server(PORT)
	if erro == OK:
		timestamp = Time.get_datetime_string_from_system(false, true)
		print(str(timestamp) + " server started...\n")
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(_player_connected)
		multiplayer.peer_disconnected.connect(_player_disconnected)
#		multiplayer.set_multiplayer_peer(peer)
		print(timestamp, " Waiting For Players!")
	else :
		timestamp = Time.get_datetime_string_from_system(false, true)
		print(str(timestamp) + " create fialed, error code:" + str(erro) + "\n")



####Load Game here. And hide our connect menu 
#@rpc("any_peer")
#func StartGame():
#	var scene = load("res://Main.tscn").instantiate()
#	get_tree().root.add_child(scene)
#	self.hide()	

func _player_connected(id: int):
	#multiplayer.rpc(id,GameManager,"get_id",[id])
	timestamp = Time.get_datetime_string_from_system(false, true)
	print(str(timestamp) + " player:"+str(id)+" connected\n")
	
	GameManager.s_players[id] = {
		"id" : id,
		"room_id" : null,
		"score" : 0,
		"map_id" : 0
	}
	#players[id] = {
	#	"id" : id,
	#	"UserName": null,
	#	"location_room" : null,
	#	"score" : 0
	#}
	
func _player_disconnected(id: int) -> void:
	timestamp = Time.get_datetime_string_from_system(false, true)
	print(str(timestamp) + " player:"+str(id)+" disconnected\n")
	#id_data[id]
	GameManager.s_players.erase(id)
	#players.erase(id)
