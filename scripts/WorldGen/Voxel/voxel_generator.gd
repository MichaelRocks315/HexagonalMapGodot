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
		map_dict[voxel.grid_position] = voxel
	create_uvs(uvs, map.size())
	interval["Setup vertex positions -- "] = Time.get_ticks_msec()	
	
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
	WorldMap.top_layer_voxels.append_array(top_voxels)
	return surface.commit()


func correct_geometry() -> Vector2i:
	var passes = 0
	var remove = 1
	var total = 0

	while remove > 0 or passes > 50:
		remove = 0

		#Adjust all solid voxels
		for prism in map:
			if prism.type == Voxel.biome.AIR:
				continue
				
			# Flatten buffer
			if prism.buffer and settings.flat_buffer:
				if prism.grid_position.y > 0:
					prism.type = Voxel.biome.AIR
					remove += 1
					continue
	
			# Ensure no overhang
			var neighbor_pos : Vector3i = prism.grid_position
			neighbor_pos.y -= 1
			if neighbor_pos.y < 1:
				continue
			if air_at_pos(neighbor_pos):
				prism.type = Voxel.biome.AIR
				remove += 1
				continue
	
			# Ensure terrace
			if settings.terrace_steps < 1:
				continue
			var table = WorldMap.get_tile_neighbor_table(prism.grid_position.x)
			for dir in table:
				neighbor_pos = prism.grid_position
				neighbor_pos.x += dir.x
				neighbor_pos.z += dir.y
				neighbor_pos.y -= settings.terrace_steps
				if air_at_pos(neighbor_pos):
					prism.type = Voxel.biome.AIR
					remove += 1
					break
		passes += 1
		total += remove
	return Vector2i(passes, total)


func build_geometry(indices: PackedInt32Array, prism_count: int):
	# Construct edges and faces
	for prism in range(prism_count):
		var prism_start = prism * 13  # Each prism has 13 vertices
		var current_prism : Voxel = map[prism]
		var neutral_neighbor : Vector3i #Same height neighbor
		var dirs = WorldMap.get_tile_neighbor_table(current_prism.grid_position.x)
		
		if current_prism.type == Voxel.biome.AIR:
			continue

		## Construct sides
		for i in range(6):
			neutral_neighbor = current_prism.grid_position
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
		var top_neighbor = current_prism.grid_position
		top_neighbor.y += 1
		if draw_face(top_neighbor):
			top_voxels.append(current_prism)
			for i in range(sides):
				# Add triangles for the top face
				indices.append(prism_start + sides + i)           # Top vertex
				indices.append(prism_start + sides + ((i + 1) % sides))      # Next top vertex
				indices.append(prism_start + 12)    # Top center vertex


func create_uvs(uvs: PackedVector2Array, prism_count: int) -> void:
	var atlas_size = 4
	var tile_size = 1.0 / atlas_size
	
	for prism in prism_count:
		# Bottom vertices
		for i in sides:
			uvs.append(Vector2(i * tile_size, 0.0))
		# Top vertices
		for i in sides:
			var angle = (float(i)/6.0) * 2.0 * PI
			uvs.append(Vector2(0.5 + 0.5 * cos(angle), 0.5 + 0.5 * sin(angle)))
		
		# Top center
		uvs.append(Vector2(0.5, 0.5))


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
