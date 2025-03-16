extends Node
class_name Pathfinder

@export var highlight_marker : PackedScene
var markers = []


func find_reachable_voxels(start : Voxel, movement_range: int, step: int) -> Array[Voxel]:
	var queue = []
	var visited = []
	var reachable_voxels : Array[Voxel]

	# Start from the initial Voxel
	queue.append({"Voxel": start, "distance": 0})
	visited.append(Vector2(start.grid_position_xz.x, start.grid_position_xz.y))

	while queue.size() > 0:
		var current = queue.pop_front()
		var current_voxel : Voxel = current["Voxel"]
		var current_distance : int = current["distance"]
		
		if current_distance > movement_range:
			continue
		
		# Add the current Voxel to the reachable list
		reachable_voxels.append(current_voxel)
		var current_pos = current_voxel.grid_position_xz
		
		var neighbor_positions = WorldMap.get_tile_neighbor_table(current_pos.x)
		# Explore neighbors
		for direction : Vector2i in neighbor_positions:
			var neighbor_coords = current_pos + direction
			if not is_voxel_valid(neighbor_coords, current_voxel.grid_position_xyz, step) or visited.has(neighbor_coords):
				continue
			var neighbor_voxel = WorldMap.map_as_dict[neighbor_coords]
			queue.append({"Voxel": neighbor_voxel, "distance": current_distance + 1})
			visited.append(neighbor_coords)

	return reachable_voxels


func is_voxel_valid(coords : Vector2i, current_pos : Vector3i, step: int) -> bool:
	var voxel : Voxel = WorldMap.map_as_dict.get(coords)
	if voxel:
		var diff = voxel.grid_position_xyz.y - current_pos.y
		if abs(diff) > step:
			return false
		if voxel.occupier == null and voxel.type != Voxel.biome.WATER:
			return true
	return false


func clear_highlight():
	if markers and markers.size() > 0:
		for m in markers:
			m.visible = false


func highlight_voxel(selected_nodes : Array[Voxel]):
	#Ensure correct marker count
	var marker_diff = selected_nodes.size() - markers.size()
	for m in range(marker_diff):
		var new_marker = highlight_marker.instantiate()
		add_child(new_marker)
		markers.append(new_marker)
	clear_highlight() # turn all markers invisible
	# Iterate over selected Voxels
	for i in range(selected_nodes.size()):
		var marker : Node3D = markers[i]
		var voxel : Voxel = selected_nodes[i]
		marker.position = voxel.collider.position
		if marker.scale.x != WorldMap.world_settings.voxel_size:
			marker.scale *= WorldMap.world_settings.voxel_size
		marker.position.y += 0.05
		marker.visible = true
