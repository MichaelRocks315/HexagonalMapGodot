extends Node
class_name Pathfinder

var neighbor_positions = WorldMap.HEXAGONAL_NEIGHBOR_DIRECTIONS
@export var highlight_marker : PackedScene
var markers = []


func find_reachable_Voxels(start : Voxel, movement_range: int) -> Array[Node3D]:
	var queue = []
	var visited = []
	var reachable_Voxels : Array[Node3D]

	# Start from the initial Voxel
	queue.append({"Voxel": start, "distance": 0})
	visited.append(Vector2(start.pos_data.grid_position.x, start.pos_data.grid_position.y))

	while queue.size() > 0:
		var current = queue.pop_front()
		var current_Voxel : Voxel = current["Voxel"]
		var current_distance : int = current["distance"]
		
		if current_distance > movement_range:
			continue
		
		# Add the current Voxel to the reachable list
		reachable_Voxels.append(current_Voxel)

		var current_pos = current_Voxel.pos_data.grid_position
		
		if WorldMap.is_map_staggered:
			if current_pos.x % 2 == 0:
				neighbor_positions = WorldMap.NEIGHBOR_DIRECTIONS_EVEN
			else:
				neighbor_positions = WorldMap.NEIGHBOR_DIRECTIONS_ODD
		
		# Explore neighbors
		for direction in neighbor_positions:
			var neighbor_coords = Vector2(current_pos.x + int(direction.x), current_pos.y + int(direction.y))
			if not is_Voxel_valid(neighbor_coords) or visited.has(neighbor_coords):
				continue
			var neighbor_Voxel = WorldMap.map_as_dict[neighbor_coords]
			queue.append({"Voxel": neighbor_Voxel, "distance": current_distance + 1})
			visited.append(neighbor_coords)

	return reachable_Voxels


func is_Voxel_valid(coords : Vector2) -> bool:
	var valid = false
	if not WorldMap.map_as_dict.has(coords):
		push_warning("Voxel not in map!")
		return false
	var Voxel = WorldMap.map_as_dict[coords]
	if Voxel:
		if Voxel.occupier == null and Voxel.mesh_data.type != Voxel.biome_type.Ocean:
			valid = true
	return valid


func clear_highlight():
	if markers and markers.size() > 0:
		for m in markers:
			m.visible = false


#func highlight_Voxel(selected_nodes: Array[Node3D]):
	##Ensure correct marker count
	#var marker_diff = selected_nodes.size() - markers.size()
	#for m in range(marker_diff):
		#var new_marker = highlight_marker.instantiate()
		#add_child(new_marker)
		#markers.append(new_marker)
	#clear_highlight() # turn all markers invisible
	## Iterate over selected Voxels
	#for i in range(selected_nodes.size()):
		#var marker = markers[i]
		#var voxel : Voxel = selected_nodes[i]
		#marker.position = voxel.position
		#marker.visible = true
