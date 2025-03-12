extends Node
class_name ObjectPlacer

@export var village : PackedScene

func place_villages(tiles : Array[Voxel], spacing : int):
	var tiles_copy = tiles.duplicate(true) #copy tiles and leave original unaffected
	var placed_positions : Array[Vector2i]
	var current_index = 0	
	tiles_copy.shuffle()
	
	while current_index < tiles_copy.size():
		# Select random tile from array
		var candidate : Voxel = tiles_copy[current_index]
		current_index += 1
		var valid = true
		
		if not candidate.placeable:
			continue
		
		# check against previous villages
		for previous : Vector2i in placed_positions:
			var c_diff = abs(previous.x - candidate.grid_position_xz.x)
			var r_diff = abs(previous.y - candidate.grid_position_xz.y)
			var delta = abs((previous.x + previous.y) - (candidate.grid_position_xz.x + candidate.grid_position_xz.y))
			var ring_distance = max(c_diff, r_diff, delta)
			if ring_distance <= spacing:
				valid = false
				break
				
		if valid:
			placed_positions.append(Vector2i(candidate.grid_position_xz.x, candidate.grid_position_xz.y))
			spawn_on_tile(candidate, village)
			for n in candidate.neighbors:
				n.placeable = false
	print("placed " + str(placed_positions.size()) + " in " + str(current_index) + " attempts")


# Spawn an object on a tile
func spawn_on_tile(tile : Voxel, scene : PackedScene):
	if not tile or not scene:
		push_warning("tile not found!")
		return

	var instance = scene.instantiate()
	add_child(instance)
	call_deferred("position_object", instance, tile.world_position, 1.0)


func position_object(object : Node3D, target_location : Vector3, add_height : float):
	object.position = target_location
	object.position.y += add_height
