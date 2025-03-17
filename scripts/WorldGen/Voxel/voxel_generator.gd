class_name VoxelGenerator

var map : Array[Voxel]
var map_dict : Dictionary[Vector3i, Voxel]
const sides = 6
var settings : GenerationSettings
var top_voxels : Array[Voxel]

# Define the base hexagon
const base_vertices = [
	Vector3(0.5, 0.0, -0.866),  # Left
	Vector3(1.0, 0.0, 0.0),  # Top-right
	Vector3(0.5, 0.0, 0.866),  # Bottom-right
	Vector3(-0.5, 0.0, 0.866),  # Bottom-left
	Vector3(-1.0, 0.0, 0.0),  # Left
	Vector3(-0.5, 0.0, -0.866)  # Top-left
	]

func generate_chunk(_map : Array[Voxel], interval) -> Mesh:
	map = _map
	settings = WorldMap.world_settings
	var verts = PackedVector3Array()
	var indices = PackedInt32Array()
	var uvs = PackedVector2Array()
	
	for voxel in map:
		verts.append_array(get_verts(voxel.world_position))
		map_dict[voxel.grid_position_xyz] = voxel
	create_uvs(uvs, map.size())
	interval["Setup vertex positions -- "] = Time.get_ticks_msec()	
	
	determine_air_voxels()
	var corrections = correct_geometry()
	print("Correction passes: ", corrections.x, ". Total voxels removed: ", corrections.y)
	build_geometry(indices, map.size())
	interval["Voxel corrections -- "] = Time.get_ticks_msec()
	
	## Create surface
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for v_index in verts.size():
		surface.set_uv(uvs[v_index])
		surface.set_smooth_group(settings.shading)
		surface.add_vertex(verts[v_index])
	for i in indices:
		surface.add_index(i)

	surface.optimize_indices_for_cache()
	surface.generate_normals()
	surface.generate_tangents()
	WorldMap.top_layer_voxels.clear()
	WorldMap.top_layer_voxels.append_array(top_voxels)
	return surface.commit()


func determine_air_voxels():
	# Find min and max noise
	var min_noise = 999999
	var max_noise = -999999
	for i in range(map.size()):
		var voxel = map[i]
		if voxel.noise < min_noise:
			min_noise = voxel.noise
		elif voxel.noise >= max_noise:
			max_noise = voxel.noise

	# calculate probabilities, noise and height
	for voxel in map:
		var noise_contribution : float = (voxel.noise - min_noise) / (max_noise - min_noise) 
		var y : float = voxel.grid_position_xyz.y
		var normalized_height : float = clampf(y / settings.max_height, 0.0, 1.0)
		var combined_probability : float = (1.0 - settings.noise_height_bias) * noise_contribution + settings.noise_height_bias * normalized_height
		voxel.air_probability = clampf(combined_probability, 0.0, 1.0)


func correct_geometry() -> Vector2i:
	var passes = 0
	var remove = 0
	var total = 0
	var bytes : PackedByteArray
	bytes.resize(map.size())
	bytes.fill(0) #0 is solid, 1 is air
	
	while true:
		# Adjust all solid voxels
		for i in range(map.size()):
			if bytes[i] == 1:
				continue
			
			#Convert to air
			var prism = map[i]
			if prism.air_probability > settings.ground_to_air_ratio and prism.grid_position_xyz.y > 0:
				prism.type = prism.biome.AIR
				remove += 1
				bytes[i] = 1
				continue

			# Flatten buffer
			if prism.buffer and settings.flat_buffer:
				if prism.grid_position_xyz.y > 0:
					prism.type = prism.biome.AIR
					remove += 1
					bytes[i] = 1
					continue
	
			# Ensure no overhang
			var neighbor_pos : Vector3i = prism.grid_position_xyz
			neighbor_pos.y -= 1
			if neighbor_pos.y < 1:
				continue
			if air_at_pos(neighbor_pos):
				prism.type = prism.biome.AIR
				remove += 1
				bytes[i] = 1
				continue
	
			# Ensure terrace
			if settings.terrace_steps < 1:
				continue
			var table = WorldMap.get_tile_neighbor_table(prism.grid_position_xz.x)
			for dir in table:
				neighbor_pos = Vector3i(prism.grid_position_xyz.x + dir.x,
										prism.grid_position_xyz.y - settings.terrace_steps,
										prism.grid_position_xyz.z + dir.y)
				if air_at_pos(neighbor_pos):
					prism.type = Voxel.biome.AIR
					remove += 1
					bytes[i] = 1
					break
		
		if remove < 1 or passes > 50:
			break
		passes += 1
		total += remove
		remove = 0  # Reset remove counter for next pass
		
	return Vector2i(passes, total)


func build_geometry(indices: PackedInt32Array, prism_count: int):
	# Construct edges and faces
	for prism in range(prism_count):
		var prism_start = prism * 13  # Each prism has 13 vertices
		var current_prism : Voxel = map[prism]
		var neutral_neighbor : Vector3i #Same height neighbor
		var dirs = WorldMap.get_tile_neighbor_table(current_prism.grid_position_xyz.x)
		
		if current_prism.type == Voxel.biome.AIR:
			continue

		## Construct sides
		for i in range(6):
			neutral_neighbor = current_prism.grid_position_xyz
			neutral_neighbor.x += dirs[i].x 
			neutral_neighbor.z += dirs[i].y
			if draw_face(neutral_neighbor):
				# First triangle of the quad (base to top)
				indices.append(prism_start + i)        # Bottom vertex
				indices.append(prism_start + ((i + 1) % sides))   # Next bottom vertex
				indices.append(prism_start + sides + i)           # Top vertex
				
				# Second triangle of the quad (top to next base)
				indices.append(prism_start + ((i + 1) % sides))   # Next bottom vertex
				indices.append(prism_start + sides + ((i + 1) % sides))      # Next top vertex
				indices.append(prism_start + sides + i)           # Top vertex
		
		## Construct top
		var top_neighbor = current_prism.grid_position_xyz
		top_neighbor.y += 1
		if draw_face(top_neighbor):
			top_voxels.append(current_prism)
			for i in range(sides):
				# Add triangles for the top face
				indices.append(prism_start + sides + i)           # Top vertex
				indices.append(prism_start + sides + ((i + 1) % sides))      # Next top vertex
				indices.append(prism_start + 12)    # Top center vertex


func create_uvs(uvs: PackedVector2Array, prism_count: int) -> void:
	# TODO: Fix UVS
	for prism in prism_count:
		for v in 13:
			uvs.append(Vector2(0.0, 0.0))


# Function to get the vertices for the base and top hexagon
func get_verts(position : Vector3) -> PackedVector3Array:
	var verts = PackedVector3Array()
	var size = settings.voxel_size
	var top = Vector3(0.0, settings.voxel_height, 0.0)
	
	# Append base vertices
	for v in base_vertices:
		verts.append(v * size + position)  # Base vertices

	# Append top vertices
	for v in base_vertices:
		verts.append(v * size + top + position)  # Top vertices
	
	# append top center vert
	verts.append(position + top) # Top center vertex
	
	return verts


func draw_face(neighbor_pos : Vector3i) -> bool:
	var neighbor = map_dict.get(neighbor_pos)
	if neighbor:
		if neighbor.type == Voxel.biome.AIR:
			return true
		else:
			return false
	return true


func air_at_pos(pos) -> bool:
	var neighbor : Voxel = map_dict.get(pos)
	if neighbor and neighbor.type == Voxel.biome.AIR:
		return true
	return false
