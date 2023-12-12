extends TileMap


var cs_players = GameManager.s_players
var cs_rooms = GameManager.s_rooms			#
var cs_room: Dictionary = {}			#"creator"= cs是当前房间id
#{ "creator": 492059137, "players_in_room": 
#{ 492059137: { "id": 492059137, "score": 0, "map_id": <null>, "room_id": 0 }, 
#806605101: { "id": 806605101, "score": 0, "map_id": <null>, "room_id": 0 } }, 
#"players_done": 0, "state": 0, "room_id": 0 }
var player1_id = 0
var player2_id = 0
var player_creator_id = 0
var opponent_id = 0
var myself_id = 0
var player_no_creator_id = 0

var local_room_id = 0

##----------------DONT CHANGE-----------------###
const main_layer = 0			#tilemap
const main_atlas_id = 0			#tilemap
var PlayerX						#玩家tilemap记号


#Input开关
var can_process_input = true

#Tile color
var white = Vector2i(0,2)  #白色在stage 1
var black = Vector2i(0,0)  #黑色在stage 2动
var red = Vector2i(0,1)    #红色禁止通行

#点击次数计数器
var input_counter = 0 #record input triggle times

###-------------------------------------------###
var set_time = 10
var N = 10 # rounds to go
##---------------------------------------------###
var data = {
	"map":{}
}

#var map_path1 = "res://mapData//save_game.dat"

var timestamp = Time.get_datetime_string_from_system(false, true)
var time_after_game = Time.get_ticks_msec ( ) 


func _ready():
	
	can_process_input = true
	#map_path1 = MapPath.map_path
	#map_path1 =  %MapPath.text
	#var file = FileAccess.open(map_path1, FileAccess.READ)
	#var content = file.get_as_text()
	#data = str_to_var(content)

	#for key in str_to_var(content).map:
	#	var item = str_to_var(content).map[key]
	#	set_cell(item.layer,item.coords,item.source_id,item.atlas_coords)
	#%FileImportDialog.popup()

	myself_id = multiplayer.get_unique_id()
	cs_room = GameManager._get_room(myself_id)			#return c_rooms[myroom_id]
#	{ "creator": 1576778491, "players_in_room": { 1576778491: { "id": 1576778491, "score": 0, "map_id": <null>, "room_id": 0 }, 1273181895: { "id": 1273181895, "score": 0, "map_id": <null>, "room_id": 0 } }, 
#"players_done": 0, "state": 0, "room_id": 0 }
	
	local_room_id = cs_room["room_id"]
	
	player1_id = cs_room["players_in_room"].keys()[0]
	player2_id = cs_room["players_in_room"].keys()[1]

	player_creator_id = cs_room["creator"]

	
	#房主 id
	if player_creator_id == player1_id:
		player_no_creator_id = player2_id
	else:
		player_no_creator_id = player1_id

	#本地，自己id 和 对手id
	if myself_id == player1_id:
		opponent_id = player2_id
	else:
		opponent_id = player1_id

	if multiplayer.get_unique_id() == player_creator_id:
		PlayerX = 1     #玩家代号,同样也是替换棋子颜色,player1是蓝色
	else:
		PlayerX = 2     #玩player2是绿色
	
	updata_input_count(input_counter)	#游戏开始时点击剩余计数器
	
	
	
	#####连通性_ready
	for i in range(-50,50):
		for j in range(-50,50):
			var mypos = Vector2i(i,j)
			if get_cell_atlas_coords(main_layer, mypos)== white:
				all_white_node[mypos] = white

			if get_cell_atlas_coords(main_layer, mypos)== black:
				all_black_node[mypos] = black
	for i in all_white_node:
		neighbour(i)				#修改 neighbour_graph，添加记录
	for i in all_black_node:
		neighbour(i) 				#修改 neighbour_graph
	romove_white_neighbour_graph = remove_entries_with_white(neighbour_graph)
	#_reeady return : romove_white_neighbour_graph  eighbour_graph 
	#####连通性_ready
	your_color()
	#----------------------------------log file—-----------------------------------#
	var verb = "Start"
	var object = "game"
	var context = ""
	var uid = myself_id
	var mydata = info_log(uid, verb, object, context)
	logging("log.json",mydata)

#----------------------------------log end—----------------------------------#
	
#------------------UI Label code-------------#
#label显示点击剩余次数
#修改 click_value的label
func updata_input_count(input_counter):
	var label_click = get_node("../ScoreDisplay/click_value")
	var click_remain = N-input_counter
	label_click.text = str(click_remain)
	
	
	
func time_left_update():
	var mytimer_label = get_node("../ScoreDisplay/time_value")
	var timer = $Timer
	var mytime_left = round(timer.time_left)
	mytimer_label.text = str(mytime_left)
func _on_timer_1s_timeout():
	time_left_update()
#计时器时间到
func _on_timer_timeout():

	can_process_input = false
	var timeout= true
	var pos_clicked = null
	timestamp = Time.get_datetime_string_from_system(false, true)
	var mylocal_room_id = local_room_id
	time_after_game = Time.get_ticks_msec() 
	GameManager.timeout.rpc_id(1,pos_clicked, PlayerX, myself_id, timestamp, time_after_game,timeout,mylocal_room_id)
#----------------------------------log file—-----------------------------------#
		
	var verb = "Pass"
	var object = "Time out"
	var context = ""
	var uid = player1_id
	var mydata = info_log(uid, verb, object, context)
	logging("log.json",mydata)
	
#----------------------------------log end—----------------------------------#
func time_on():
	var timer = $Timer
	timer.start()

func time_off():
	var timer = $Timer
	timer.stop()
	
func update_score_p1(score_p1):
	var label_score = get_node("../ScoreDisplay/p1_sc_value")
	label_score.text = str(score_p1)
func update_score_p2(score_p2):
	var label_score = get_node("../ScoreDisplay/p2_sc_value")
	label_score.text = str(score_p2)

func your_color():
	var label_color = get_node("../ScoreDisplay/color_value")
	var mycolor
	if PlayerX == 1:
		mycolor = "蓝色"
	else:
		mycolor = "绿色"
	
	label_color.text =  mycolor
#------------------UI Label code-------------#



#点击白色区域，记录位置信息等
#输出: 发送点击位置到服务器

func _input(event):
	if event is InputEventMouseButton and can_process_input == true:

		if (event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()):
			timestamp = Time.get_datetime_string_from_system(false, true)
			time_after_game = Time.get_ticks_msec() 
			var global_clicked = event.position
			var pos_clicked = local_to_map(to_local(global_clicked))
			var current_atlas_coords = get_cell_atlas_coords(main_layer, pos_clicked)	#黑白红
			var current_tile_alt = get_cell_alternative_tile(main_layer, pos_clicked)	#白 + 1 =蓝，白 + 2 = 绿
			var new_tile_alt = PlayerX
			#log
			var mylocal_room_id = local_room_id
#----------------------------------log file—-----------------------------------#
			
			var verb = "input"
			var object = "position"
			if current_atlas_coords == white:
				object = "white"
			elif current_atlas_coords == black:
				object = "black"
			var context = {}
			context["position"] = pos_clicked
			if can_process_input == true:
				context["can_process_input"] = "true"
			else:
				context["can_process_input"] = "false"
			var uid = myself_id
			var mydata = info_log(uid, verb, object, context)
			print(mydata)
			logging("log.json",mydata)
#----------------------------------log end—----------------------------------#
			if current_atlas_coords == white and input_counter<N and current_tile_alt == 0:
				#如果不是服务器，发送点击位置到服务器
				can_process_input = false
				
				
				var timer=$Timer	
				if !timer.is_stopped():
					timer.stop()

#
				
				if !multiplayer.is_server():
					var timeout = false			#区分超时

					GameManager.process_click.rpc_id(1, pos_clicked, PlayerX, myself_id, timestamp, time_after_game,timeout,mylocal_room_id)









#--------------------------连通性问题 开始------------------#

#/***
# *               ii.                                         ;9ABH,          
# *              SA391,                                    .r9GG35&G          
# *              &#ii13Gh;                               i3X31i;:,rB1         
# *              iMs,:,i5895,                         .5G91:,:;:s1:8A         
# *               33::::,,;5G5,                     ,58Si,,:::,sHX;iH1        
# *                Sr.,:;rs13BBX35hh11511h5Shhh5S3GAXS:.,,::,,1AG3i,GG        
# *                .G51S511sr;;iiiishS8G89Shsrrsh59S;.,,,,,..5A85Si,h8        
# *               :SB9s:,............................,,,.,,,SASh53h,1G.       
# *            .r18S;..,,,,,,,,,,,,,,,,,,,,,,,,,,,,,....,,.1H315199,rX,       
# *          ;S89s,..,,,,,,,,,,,,,,,,,,,,,,,....,,.......,,,;r1ShS8,;Xi       
# *        i55s:.........,,,,,,,,,,,,,,,,.,,,......,.....,,....r9&5.:X1       
# *       59;.....,.     .,,,,,,,,,,,...        .............,..:1;.:&s       
# *      s8,..;53S5S3s.   .,,,,,,,.,..      i15S5h1:.........,,,..,,:99       
# *      93.:39s:rSGB@A;  ..,,,,.....    .SG3hhh9G&BGi..,,,,,,,,,,,,.,83      
# *      G5.G8  9#@@@@@X. .,,,,,,.....  iA9,.S&B###@@Mr...,,,,,,,,..,.;Xh     
# *      Gs.X8 S@@@@@@@B:..,,,,,,,,,,. rA1 ,A@@@@@@@@@H:........,,,,,,.iX:    
# *     ;9. ,8A#@@@@@@#5,.,,,,,,,,,... 9A. 8@@@@@@@@@@M;    ....,,,,,,,,S8    
# *     X3    iS8XAHH8s.,,,,,,,,,,...,..58hH@@@@@@@@@Hs       ...,,,,,,,:Gs   
# *    r8,        ,,,...,,,,,,,,,,.....  ,h8XABMMHX3r.          .,,,,,,,.rX:  
# *   :9, .    .:,..,:;;;::,.,,,,,..          .,,.               ..,,,,,,.59  
# *  .Si      ,:.i8HBMMMMMB&5,....                    .            .,,,,,.sMr
# *  SS       :: h@@@@@@@@@@#; .                     ...  .         ..,,,,iM5
# *  91  .    ;:.,1&@@@@@@MXs.                            .          .,,:,:&S
# *  hS ....  .:;,,,i3MMS1;..,..... .  .     ...                     ..,:,.99
# *  ,8; ..... .,:,..,8Ms:;,,,...                                     .,::.83
# *   s&: ....  .sS553B@@HX3s;,.    .,;13h.                            .:::&1
# *    SXr  .  ...;s3G99XA&X88Shss11155hi.                             ,;:h&,
# *     iH8:  . ..   ,;iiii;,::,,,,,.                                 .;irHA  
# *      ,8X5;   .     .......                                       ,;iihS8Gi
# *         1831,                                                 .,;irrrrrs&@
# *           ;5A8r.                                            .:;iiiiirrss1H
# *             :X@H3s.......                                .,:;iii;iiiiirsrh
# *              r#h:;,...,,.. .,,:;;;;;:::,...              .:;;;;;;iiiirrss1
# *             ,M8 ..,....,.....,,::::::,,...         .     .,;;;iiiiiirss11h
# *             8B;.,,,,,,,.,.....          .           ..   .:;;;;iirrsss111h
# *            i@5,:::,,,,,,,,.... .                   . .:::;;;;;irrrss111111
# *            9Bi,:,,,,......                        ..r91;;;;;iirrsss1ss1111
# */


#--------------------------连通性问题 开始------------------#
#关于最终函数是这个func dps_conn_white(start, end):
#注意start end都应该是白色点
#dps_conn_white(start, end) return true or false
#代表 start 和 end的白点具有游戏里连通性

var offset = [Vector2i(1,0),Vector2i(1,1),Vector2i(0,1),Vector2i(-1,1),Vector2i(-1,0),Vector2i(-1,-1),Vector2i(0,-1),Vector2i(1,-1)]
var nullcolor= Vector2i(-1,-1)
# Called when the node enters the scene tree for the first time.



var all_white_node = {}		#所有white node position, {"位置":(0,2)} *dict
var all_black_node = {}		#所有black node position, {"位置":(0,0)}
var neighbour_graph = {}		#*dict{"level1":{level2:color}}------level1:所有black,white node pos
								#level2: all black,white nodes that is level1 node neighbour.和level1相邻的所有node
								#color: level2_color
var romove_white_neighbour_graph
#neighbour_graph 在 _ready 被加入所有 node的 相邻信息。结构如上

#_ready 出也有连通输出设定啦，去那里看看

#func 用于寻找pos 附近的相邻黑白点。用在_ready
# 用于寻找pos附近的相邻黑白点
func neighbour(pos):
	var mypos = Vector2i(0, 0)
	var mydict_8cell = {}

	for i in offset:
		mypos = pos + i  # 8个方向的坐标

		var cell_color = get_cell_atlas_coords(main_layer, mypos)
		if cell_color == white or cell_color == black:
			mydict_8cell[mypos] = cell_color

	neighbour_graph[pos] = mydict_8cell

var connectivity_white = {}   #{level1: {level2:color}}  level1代表

#return 版本func neighbour
func neighbour_return(pos):
	var mypos = Vector2i(0, 0)
	var mydict_8cell = {}
	var neighbour_single = {}
	for i in offset:
		mypos = pos + i  # 8个方向的坐标

		var cell_color = get_cell_atlas_coords(main_layer, mypos)
		if cell_color == white or cell_color == black:
			mydict_8cell[mypos] = cell_color
	neighbour_single[pos] = mydict_8cell
	return mydict_8cell



#删除所有白色点周围的黑色点
func remove_entries_with_white(neighbour_graph):
	var new_graph = neighbour_graph.duplicate()  # 创建一个新字典作为副本

	# 找到所有一级键，这些键的字典中含有white值
	var keys_to_remove = []
	for pos in new_graph.keys():
		for neighbour_pos in new_graph[pos].keys():
			if new_graph[pos][neighbour_pos] == white:
				keys_to_remove.append(pos)
				break  # 找到white值后，中断循环

	# 删除所有含有white值的一级键
	for key in keys_to_remove:
		new_graph.erase(key)

	return new_graph


#----------------------------连通问题思路------------------------------
#现在寻找两两白色点之间的连通性，然后把白色点的连通性关系写在dict中
#如何寻找白色的连通性？ 从dict all_white_node白色中选pos，检测两两之间的连通性。起始点和目标点
#
#func dfs: 从一个起始点start开始出发,加入seen_road中
#repeat
#列出所有起始点相邻点 neighbour_graph[start]->{1p:color,2p:color,3p}...从neighbour_graph中， 检查 neighbour_graph[start][1p],2p,3p的颜色。加入seen_road中。(列出其中白色点，判断是否是目标点。
#是加那么就终止......否........什么都不做)
#如果没有白色点，检查 for i in 1p,2p,p3:
#dfs(i)
#
#
#最终seen_road 应当包括起始和目标点
#----------------------------------------------------------------------
#---------连通问题-----------------------
#func dfs: 从一个起始点start开始出发,加入seen_road中

var seen_road = {}
#dfs初级递归
func dfs(seen_road, graph, start, end):
	if start not in seen_road:
		seen_road[start] = true


		if graph.has(start):
			for new_neighbour in graph[start]:
				if new_neighbour == end:
					seen_road[new_neighbour] = true

					return true
				else:
					if dfs(seen_road, graph, new_neighbour, end):
						return true

	return false

	


#-------------------------------------------------------------------------------------#
#现在的问题是，如何描述我们的连接问题。我们的连接问题在于，白色附近的黑色点会终结路径。
#那么我们应该把白色附近的黑色点也变成墙的概念
#因此 romove_white_neighbour_graph 是 去除 白色附近黑色点的 neighbour_graph。(白色点依旧保留)
#这样，romove_white_neighbour_graph 周围的黑色点，成为只进不能出来的黑洞，也是墙 (但是我们能到达，却不能连接其它)
#这里的问题在于，我们出发点的白色周围的黑色也成为了黑洞，因此。我们需要romove_white_neighbour_graph补全计划。
#我们的目标点的卫星点 成为了我们真正的end, 因此end 是多个结束点的卫星点。
#那么上面的问题就可以用dps解决
func dps_conn_white(start, end):
	#romove_white_neighbour_graph 补全计划， 用romove_white_neighbour_graph[pos] = neighbour_return(pos)补全
	#问题是pos是什么？pos是起始点的卫星点。如何寻找一个点start的卫星点? for i in romove_white_neighbour_graph[start]: i既是所有卫星点

	if start == Vector2i(999,999) or end == Vector2i(999,999):
		return false
	else:
		var my_romove_white_neighbour_graph = romove_white_neighbour_graph.duplicate()		#避免全局修改
		
		for i in romove_white_neighbour_graph[start]:

			my_romove_white_neighbour_graph[i] = neighbour_return(i)			#my_romove_white_neighbour_graph为补全graph

		#接下来的问题是，目标点是什么？ 目标点是结束点的卫星点， 因此 for i in romove_white_neighbour_graph[end]:  i 既是所有目标点
		var myrecord = {}
		for i in romove_white_neighbour_graph[end]:
		#start应该是动态的
			seen_road = {}
			myrecord[i] = dfs(seen_road, my_romove_white_neighbour_graph, start, i)		#应该return 每个 i结束点对应的 true or false

		return has_true_value(myrecord)

#最终函数在这里
#func dps_conn_white(start, end): 的下级小函数
func has_true_value(record):
	for key in record:
		if record[key] == true:
			return true
	return false
#--------------------------------------------------------------------------------------------------------------------#
var seen_path={}
var unseen_path = {}
func eight_cells_check(pos):
	seen_path[pos] = nullcolor
	var mypos = Vector2i(0,0)	
	var mydict_road = {}
	var mydict_target = {}
	for i in offset:

		mypos = pos + i			#8个方向的坐标
		if mypos not in seen_path:	#如果我们没见过这个坐标
			if get_cell_atlas_coords(main_layer, mypos)== white:
				mydict_target[mypos] = white
				seen_path[mypos] = nullcolor
			elif get_cell_atlas_coords(main_layer, mypos)==black:
				mydict_road[mypos] = black
				seen_path[mypos] = nullcolor
			elif get_cell_atlas_coords(main_layer, mypos)==nullcolor:
				seen_path[mypos] = nullcolor

	return [mydict_target,mydict_road]


#---------------连通性小组问题 12/7/2023------------------------------#
#如果 pos_list 是 pos array.那么其中哪些是连在一起的
#create_graph 用于制作pos_list的连接graph
func create_graph(pos_list: Array) -> Dictionary:
	var graph = {}  # 初始化图的字典

	# 遍历 pos_list 中的每个点
	for i in range(pos_list.size()):
		var neighbors = []  # 初始化当前点的邻居列表
		for j in range(pos_list.size()):
			# 确保不与自己比较
			if i != j and dps_conn_white(pos_list[i], pos_list[j]):
				neighbors.append(pos_list[j])  # 如果相邻，则添加到邻居列表
		graph[pos_list[i]] = neighbors  # 将邻居列表添加到图字典

	return graph  # 返回表示邻接关系的图


func find_shortest_path(graph: Dictionary, start_pos, end_pos) -> Array:
	if start_pos == end_pos:
		return [start_pos]

	var queue = []
	queue.push_back([start_pos])  # 队列中的元素将是路径列表
	var visited = {start_pos: true}

	while queue.size() > 0:
		var path = queue.pop_front()  # 取出路径
		var node = path[path.size() - 1]  # 当前路径的最后一个节点是最新的节点

		if node in graph:
			for neighbour in graph[node]:
				if neighbour == end_pos:
					path.append(neighbour)  # 找到路径，加入结束节点并返回路径
					return path
				elif not visited.has(neighbour):
					visited[neighbour] = true
					var new_path = path.duplicate()  # 复制当前路径
					new_path.append(neighbour)  # 加入邻居
					queue.push_back(new_path)  # 将新路径加入队列

	return []  # 如果没有路径，则返回空列表


func set_path(start_num, end_num, pos_list: Array) -> Array:
	var myarray = []
	if pos_list.size() > 1:
		var mygrpah = create_graph(pos_list)
		var start_pos = pos_list[start_num]
		var send_pos = pos_list[end_num]
		myarray = find_shortest_path(mygrpah, start_pos,send_pos)
		
	return myarray


func spec_score(myarray):
	var totalscore = 0

	if myarray.size()>1:
		for i in range(myarray.size()-1):
			var j = i+1
			var x_value1 = myarray[i].x
			var y_value1 = myarray[i].y
			var x_value2 = myarray[j].x
			var y_value2 = myarray[j].y
			var myscorex = abs(x_value1 - x_value2)
			var myscorey = abs(y_value1 - y_value2)
			var myscore = max(myscorex,myscorey)-1

			
			totalscore += myscore
	return totalscore
	
#调用方法
#输入是pos_list

#var mypos_list = pos_list
#var mygrpah = create_graph(pos_list)
#var start_number = 0
#var end_number = 1
#
#
#var myarray = set_path(start_number,end_number,mypos_list)
#var mysocre_2 = spec_score(myarray)


#输出是要被权重的分数
#----------------------------------------------#



#-----------------------------------------------------------------------------------------#
#/***
# *               ii.                                         ;9ABH,          
# *              SA391,                                    .r9GG35&G          
# *              &#ii13Gh;                               i3X31i;:,rB1         
# *              iMs,:,i5895,                         .5G91:,:;:s1:8A         
# *               33::::,,;5G5,                     ,58Si,,:::,sHX;iH1        
# *                Sr.,:;rs13BBX35hh11511h5Shhh5S3GAXS:.,,::,,1AG3i,GG        
# *                .G51S511sr;;iiiishS8G89Shsrrsh59S;.,,,,,..5A85Si,h8        
# *               :SB9s:,............................,,,.,,,SASh53h,1G.       
# *            .r18S;..,,,,,,,,,,,,,,,,,,,,,,,,,,,,,....,,.1H315199,rX,       
# *          ;S89s,..,,,,,,,,,,,,,,,,,,,,,,,....,,.......,,,;r1ShS8,;Xi       
# *        i55s:.........,,,,,,,,,,,,,,,,.,,,......,.....,,....r9&5.:X1       
# *       59;.....,.     .,,,,,,,,,,,...        .............,..:1;.:&s       
# *      s8,..;53S5S3s.   .,,,,,,,.,..      i15S5h1:.........,,,..,,:99       
# *      93.:39s:rSGB@A;  ..,,,,.....    .SG3hhh9G&BGi..,,,,,,,,,,,,.,83      
# *      G5.G8  9#@@@@@X. .,,,,,,.....  iA9,.S&B###@@Mr...,,,,,,,,..,.;Xh     
# *      Gs.X8 S@@@@@@@B:..,,,,,,,,,,. rA1 ,A@@@@@@@@@H:........,,,,,,.iX:    
# *     ;9. ,8A#@@@@@@#5,.,,,,,,,,,... 9A. 8@@@@@@@@@@M;    ....,,,,,,,,S8    
# *     X3    iS8XAHH8s.,,,,,,,,,,...,..58hH@@@@@@@@@Hs       ...,,,,,,,:Gs   
# *    r8,        ,,,...,,,,,,,,,,.....  ,h8XABMMHX3r.          .,,,,,,,.rX:  
# *   :9, .    .:,..,:;;;::,.,,,,,..          .,,.               ..,,,,,,.59  
# *  .Si      ,:.i8HBMMMMMB&5,....                    .            .,,,,,.sMr
# *  SS       :: h@@@@@@@@@@#; .                     ...  .         ..,,,,iM5
# *  91  .    ;:.,1&@@@@@@MXs.                            .          .,,:,:&S
# *  hS ....  .:;,,,i3MMS1;..,..... .  .     ...                     ..,:,.99
# *  ,8; ..... .,:,..,8Ms:;,,,...                                     .,::.83
# *   s&: ....  .sS553B@@HX3s;,.    .,;13h.                            .:::&1
# *    SXr  .  ...;s3G99XA&X88Shss11155hi.                             ,;:h&,
# *     iH8:  . ..   ,;iiii;,::,,,,,.                                 .;irHA  
# *      ,8X5;   .     .......                                       ,;iihS8Gi
# *         1831,                                                 .,;irrrrrs&@
# *           ;5A8r.                                            .:;iiiiirrss1H
# *             :X@H3s.......                                .,:;iii;iiiiirsrh
# *              r#h:;,...,,.. .,,:;;;;;:::,...              .:;;;;;;iiiirrss1
# *             ,M8 ..,....,.....,,::::::,,...         .     .,;;;iiiiiirss11h
# *             8B;.,,,,,,,.,.....          .           ..   .:;;;;iirrsss111h
# *            i@5,:::,,,,,,,,.... .                   . .:::;;;;;irrrss111111
# *            9Bi,:,,,,......                        ..r91;;;;;iirrsss1ss1111
# */

#--------------------------连通性问题 结束------------------#

var pos_list_p1 = []
var pos_list_p2 = []
#输入是来自服务器的位置信息
#输出修改pos_list_p1， pos_list_p2。Where存储所有的p1,p2玩家的pos_list
@rpc("any_peer")
func set_cell_color(player1_pos,player2_pos,playerx_winner):
	input_counter += 1
	time_on()
	updata_input_count(input_counter)	##修改 click_value的label
	if player1_pos != null:
		pos_list_p1.append(player1_pos)
		
	if player2_pos != null:
		pos_list_p2.append(player2_pos)
		
	if playerx_winner == 0:
		
		sync_tile_change(player1_pos, white, 1)
		sync_tile_change(player2_pos, white, 2)
	elif playerx_winner == 1:					#player 1 win
		player2_pos = null
		sync_tile_change(player1_pos, white, 1)
	elif playerx_winner == 2:
		player1_pos = null
		sync_tile_change(player2_pos, white, 2)
	
	
	can_process_input = true
	



var score_p1 = 0
var score_p2 = 0
func sync_tile_change(pos_clicked,atlas_color, tile_alt):
	if N - input_counter == 0:
		time_off()
	
	if !pos_clicked == Vector2i(999,999): #if pos_clicked == Vector2i(999,999), then pass
		set_cell(main_layer, pos_clicked, main_atlas_id, atlas_color, tile_alt)
		var pos_list = pos_list_p1
		
		
		score_p1 = get_score(pos_list)
		update_score_p1(score_p1)
		
		pos_list = pos_list_p2
		score_p2 = get_score(pos_list)
		update_score_p2(score_p2)
#----------------------------------log file—-----------------------------------#
		
		var verb = "Score"
		var object = score_p1
		var context = ""
		var uid = player1_id
		var mydata = info_log(uid, verb, object, context)
		logging("log.json",mydata)
		
		verb = "Score"
		object = score_p2
		context = ""
		uid = player2_id
		mydata = info_log(uid, verb, object, context)
		logging("log.json",mydata)
#----------------------------------log end—----------------------------------#
	else:
		pass


#---------------得分计算------------

#pos_list_p1， pos_list_p2。Where存储所有的p1,p2玩家的pos_list *array
#关于最终函数是这个func dps_conn_white(start, end):
#注意start end都应该是白色点
#dps_conn_white(start, end) return true or false
#代表 start 和 end的白点具有游戏里连通性


#输入的是一个玩家的 pos_list。*array
#return 一个pos_list 连接得到的分数
func general_score(pos_list):
	var myscore_out = 0
	for i in range(len(pos_list)):
		for j in range(i + 1, len(pos_list)):
			if dps_conn_white(pos_list[i],pos_list[j]):		#判断是否相连
				var x_value1 = pos_list[i].x
				var y_value1 = pos_list[i].y
				var x_value2 = pos_list[j].x
				var y_value2 = pos_list[j].y
				var myscorex = abs(x_value1 - x_value2)
				var myscorey = abs(y_value1 - y_value2)
				var myscore = max(myscorex,myscorey)-1
				myscore_out += myscore

	return myscore_out

func get_score(pos_list):
	var score_out = 0
	
	
	var mypos_list = pos_list
	var mygrpah = create_graph(pos_list)
	print(mygrpah)
	print("!!!!!!!!!!!!!!!!!!!!!!!")
	var start_number = 0
	var end_number = 1
	var myarray = set_path(start_number,end_number,mypos_list)
	var myscore_2 = spec_score(myarray)


	var myscore_1 = general_score(pos_list)
	
	score_out = myscore_1*10 + myscore_2*40
	return score_out
#---------------------------------------------------------------#

#---------------------------------------------------------------#

#----------------------------------log file—-----------------------------------#
func logging(file_name, content):
	GameManager.logging_server.rpc_id(1,file_name,content)
#	var path = "user://Inputlogs//" + file_name
#	var file = FileAccess.open(path, FileAccess.READ_WRITE)
#	if FileAccess.file_exists(path):
#
#		if file:
#			var json_string = JSON.stringify(content)
#			file.seek_end()
#			file.store_line(json_string + "\n")
#			file.close()
#	else:
#		file= FileAccess.open(path, FileAccess.WRITE)
#		if file:
#			var json_string = JSON.stringify(content)
#			file.seek_end()
#			file.store_line(json_string + "\n")
#			file.close()

func info_log(uid, verb, object, context):
	var mytimestamp = Time.get_datetime_string_from_system(false, true)
	var mytimestamp_msec = Time.get_ticks_msec ( )
	var mydata = {
		"uid" : uid,
		"verb" : verb,
		"object" : object,
		"context" : context,
		"timestamp" : mytimestamp,
		"Time_After_Start" : mytimestamp_msec
	}
	return mydata

	######Game start Log###########
#	var verb = "Start"
#	var object = "game"
#	var context = ""
#	var mydata = info_log(uid, verb, object, context)
#	logging("log.json",mydata)
#----------------------------------log file—-----------------------------------#


######For test#####No use




####
func _on_file_import_dialog_file_selected(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	data = str_to_var(content)

	for key in str_to_var(content).map:
		var item = str_to_var(content).map[key]
		set_cell(item.layer,item.coords,item.source_id,item.atlas_coords)


#######################################



