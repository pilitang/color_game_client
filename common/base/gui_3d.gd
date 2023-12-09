class_name Gui3D
extends Node3D

# The size of the quad mesh itself.
var quad_mesh_size

# Used for checking if the mouse was pressed inside the Area3D
var is_mouse_held = false
# The last non-empty mouse position. Used when dragging outside of the box.
var last_mouse_pos3D = null
# The last processed input touch/mouse event. To calculate relative movement.
var last_mouse_pos2D = null


@export var node_viewport_path : NodePath 
@export var node_quad_path : NodePath 
@export var node_area_path : NodePath 

@onready var node_viewport : SubViewport = get_node(node_viewport_path)
@onready var node_quad : MeshInstance3D = get_node(node_quad_path)
@onready var node_area : Area3D = get_node(node_area_path)

func _ready():
	#TODO:fix
#	node_viewport.get_texture().flags =Texture2D.FLAG_FILTER

	# If the material is NOT set to use billboard settings, then avoid running billboard specific code
	if node_quad.get_surface_override_material(0) == null or node_quad.get_surface_override_material(0).billboard_mode == BaseMaterial3D.BillboardMode.BILLBOARD_DISABLED:
		set_process(false)

#func _process(_delta):
#	# NOTE: Remove this function if you don't plan checked using billboard settings.
#	rotate_area_to_billboard()

func _unhandled_input(event):
	# Check if the event is a non-mouse/non-touch event
	if not node_quad.visible : return 
	
	var is_mouse_event = false
#	for mouse_event in [InputEventMouseButton,InputEventMouseMotion,InputEventScreenDrag,InputEventScreenTouch] :
#		if event is mouse_event :
#			is_mouse_event = true
#			break
	if event is InputEventMouseButton or event is InputEventMouseMotion or event is InputEventScreenDrag or event is InputEventScreenTouch :
		is_mouse_event = true


	
	# Detect mouse being held to mantain event while outside of bounds. Avoid orphan clicks
	# If the event is a mouse/touch event and/or the mouse is either held or inside the area, then
	# we need to do some additional processing in the handle_mouse function before passing the event to the viewport.
	# If the event is not a mouse/touch event, then we can just pass the event directly to the viewport.
	
		# Get mesh size to detect edges and make conversions. This code only support PlaneMesh and QuadMesh.

	quad_mesh_size = node_quad.mesh.size
	if is_mouse_event :
		var mouse_pos3D = find_mouse(event.position ) 
		if (mouse_pos3D !=null or is_mouse_held):
			handle_mouse(event.xformed_by(Transform2D.IDENTITY) , mouse_pos3D)
	else :
		node_viewport.push_input(event) 

# Handle mouse events inside Area3D. (Area3D.input_event had many issues with dragging)
func handle_mouse(event,mouse_pos3D):
	
	# Detect mouse being held to mantain event while outside of bounds. Avoid orphan clicks
	if event is InputEventScreenTouch:
		is_mouse_held = event.pressed

	# Check if the mouse is outside of bounds, use last position to avoid errors
	# NOTE: mouse_exited signal was unrealiable in this situation
	if mouse_pos3D != null:
		# Convert click_pos from world coordinate space to a coordinate space relative to the Area3D node.
		# NOTE: affine_inverse accounts for the Area3D node's scale, rotation, and position in the scene!
		mouse_pos3D = node_area.global_transform.affine_inverse() * mouse_pos3D
		last_mouse_pos3D = mouse_pos3D
	else:
		mouse_pos3D = last_mouse_pos3D
		if mouse_pos3D == null:
			mouse_pos3D = Vector3.ZERO

	# TODO: adapt to bilboard mode or avoid completely

	# convert the relative event position from 3D to 2D
	var mouse_pos2D = Vector2(mouse_pos3D.x, -mouse_pos3D.y)

	# Right now the event position's range is the following: (-quad_size/2) -> (quad_size/2)
	# We need to convert it into the following range: 0 -> quad_size
	mouse_pos2D.x += quad_mesh_size.x / 2
	mouse_pos2D.y += quad_mesh_size.y / 2
	# Then we need to convert it into the following range: 0 -> 1
	mouse_pos2D.x = mouse_pos2D.x / quad_mesh_size.x
	mouse_pos2D.y = mouse_pos2D.y / quad_mesh_size.y

	# Finally, we convert the position to the following range: 0 -> viewport.size
	mouse_pos2D.x = mouse_pos2D.x * node_viewport.size.x
	mouse_pos2D.y = mouse_pos2D.y * node_viewport.size.y
	# We need to do these conversions so the event's position is in the viewport's coordinate system.

	# Set the event's position and global position.
	event.position = mouse_pos2D

	# If the event is a mouse motion event...
	if event is InputEventMouseMotion:
		# If there is not a stored previous position, then we'll assume there is no relative motion.
		if last_mouse_pos2D == null:
			event.relative = Vector2(0, 0)
		# If there is a stored previous position, then we'll calculate the relative position by subtracting
		# the previous position from the new position. This will give us the distance the event traveled from prev_pos
		else:
			event.relative = mouse_pos2D - last_mouse_pos2D
	# Update last_mouse_pos2D with the position we just calculated.
	last_mouse_pos2D = mouse_pos2D
	# Finally, send the processed input event to the viewport.
	node_viewport.push_input(event)



func find_mouse(viewPortPositon):
	var camera = get_viewport().get_camera_3d()
	var dist = find_further_distance_to(camera.transform.origin)
	# From camera center to the mouse position in the Area3D.
	var parameters = PhysicsRayQueryParameters3D.new()
	parameters.from = camera.project_ray_origin(viewPortPositon)
	parameters.to = parameters.from + camera.project_ray_normal(viewPortPositon) * dist

	# Manually raycasts the area to find the mouse position.
	parameters.collision_mask = node_area.collision_layer
	parameters.collide_with_bodies = false
	parameters.collide_with_areas = true
	var result = get_world_3d().direct_space_state.intersect_ray(parameters)

	if result.size() > 0:
		return result.position
	else:
		return null



func find_further_distance_to(origin):
	# Find edges of collision and change to global positions
	var edges = []
	edges.append(node_area.to_global(Vector3(quad_mesh_size.x / 2, quad_mesh_size.y / 2, 0)))
	edges.append(node_area.to_global(Vector3(quad_mesh_size.x / 2, -quad_mesh_size.y / 2, 0)))
	edges.append(node_area.to_global(Vector3(-quad_mesh_size.x / 2, quad_mesh_size.y / 2, 0)))
	edges.append(node_area.to_global(Vector3(-quad_mesh_size.x / 2, -quad_mesh_size.y / 2, 0)))

	# Get the furthest distance between the camera and collision to avoid raycasting too far or too short
	var far_dist = 0
	var temp_dist
	for edge in edges:
		temp_dist = origin.distance_to(edge)
		if temp_dist > far_dist:
			far_dist = temp_dist

	return far_dist


func rotate_area_to_billboard():
	var billboard_mode = node_quad.get_surface_override_material(0).params_billboard_mode

	# Try to match the area with the material's billboard setting, if enabled
	if billboard_mode > 0:
		# Get the camera
		var camera = get_viewport().get_camera_3d()
		# Look in the same direction as the camera
		var look = camera.to_global(Vector3(0, 0, -100)) - camera.global_transform.origin
		look = node_area.position + look

		# Y-Billboard: Lock Y rotation, but gives bad results if the camera is tilted.
		if billboard_mode == 2:
			look = Vector3(look.x, 0, look.z)

		node_area.look_at(look, Vector3.UP)

		# Rotate in the Z axis to compensate camera tilt
		node_area.rotate_object_local(Vector3.BACK, camera.rotation.z)

