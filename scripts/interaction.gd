extends Node3D

@export var voxel_cursor_scene : PackedScene
@export var unit_cursor_scene : PackedScene
@export var main_camera : Camera3D
@export var p_finder : Pathfinder
var selected_voxel : Node3D
var selected_unit : Unit
var unit_moves : Array[Voxel]
# Cursors
var voxel_cursor : Node3D
var unit_cursor : Node3D
var initialized = false

func init():
	if initialized:
		return
	if not voxel_cursor or voxel_cursor == null:
		voxel_cursor = voxel_cursor_scene.instantiate()
		add_child(voxel_cursor)
	if not unit_cursor:
		unit_cursor = unit_cursor_scene.instantiate()
		add_child(unit_cursor)
	
	var scalar = WorldMap.world_settings.voxel_size
	voxel_cursor.scale_object_local(Vector3(scalar, 1.0, scalar))
	deselect()
	initialized = true


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		var mouse_pos = get_viewport().get_mouse_position()
		var origin = main_camera.project_ray_origin(mouse_pos)
		var dir = main_camera.project_ray_normal(mouse_pos)
		var end = origin + dir * 1000
		var hit_object = raycast_at_mouse(origin, end) #returns the collider
		if not hit_object:
			return
		if Input.is_action_just_pressed("Click"):
			attempt_select(hit_object)
		elif Input.is_action_just_pressed("RightClick"):
			attempt_move_unit(hit_object)


func raycast_at_mouse(origin, end) -> Node3D:
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		var collision = get_world_3d().direct_space_state.intersect_ray(query)
		if collision and collision.has("collider"):
			var hit = collision.collider
			return hit
		else:
			deselect()
			return null


func deselect():
	hide_cursor(voxel_cursor)
	hide_cursor(unit_cursor)
	unit_moves.clear()
	selected_unit = null
	p_finder.clear_highlight()


func attempt_select(hit : Node3D):
	deselect()
	if hit.is_in_group("voxels"):
		highlight_voxel(hit)
		return
	if hit.is_in_group("units"):
		select_unit(hit)
	elif hit.get_parent().is_in_group("units"):
		select_unit(hit.get_parent())


func attempt_move_unit(hit):
	if hit is not VoxelCollider:
		print("not a voxelcollider")
		return
	if not selected_unit or not unit_moves.has(hit.voxel):
		print("Invalid Move Attempt")
		return

	selected_unit.place_unit(hit.position, hit)
	deselect()


func select_unit(unit : Unit):
	selected_voxel = null
	selected_unit = unit
	hide_cursor(voxel_cursor)
	if unit is Unit:
		highlight_unit(unit)
		unit_moves = p_finder.find_reachable_voxels(unit.occupied_voxel, unit.movement_range, unit.max_height_movement)
		p_finder.highlight_voxel(unit_moves)


func highlight_voxel(voxel_col : VoxelCollider):
	selected_unit = null
	selected_voxel = voxel_col
	hide_cursor(unit_cursor)
	move_cursor(voxel_cursor, voxel_col.global_position)
	voxel_cursor.visible = true
	animate_cursor(voxel_cursor)
	#print(voxel.voxel.type) # voxel of the collider


func highlight_unit(unit):
	move_cursor(unit_cursor, unit.position)
	unit_cursor.visible = true


## move cursor with optional height difference
func move_cursor(cursor : Node3D, pos : Vector3, height : float = 0):
	cursor.position = pos
	if height != 0:
		voxel_cursor.position.y += height


func animate_cursor(cursor : Node3D):
	var tween = get_tree().create_tween()
	var initial_scale = cursor.scale
	var target_scale = initial_scale * 1.15
	tween.set_trans(Tween.TRANS_SPRING)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(cursor, "scale", target_scale, 0.175)
	tween.tween_property(cursor, "scale", initial_scale, 0.2)


func hide_cursor(cursor : Node3D):
	if cursor:
		move_cursor(cursor, Vector3.ZERO, -10)
		cursor.visible = false
