class_name VoxelGenerator

var map : Array[Voxel]
var map_dict : Dictionary[Vector3i, Voxel]
const sides = 6
var debug_cube : Node3D

# Define the base hexagon
const base_vertices = [
	Vector3(0.5, 0.0, -0.866),  # Left
	Vector3(1.0, 0.0, 0.0),  # Top-right
	Vector3(0.5, 0.0, 0.866),  # Bottom-right
	Vector3(-0.5, 0.0, 0.866),  # Bottom-left
	Vector3(-1.0, 0.0, 0.0),  # Left
	Vector3(-0.5, 0.0, -0.866)  # Top-left
	]

func generate_chunk(_map : Array[Voxel], prism_size : float, height: float, cube) -> Mesh:
	map = _map
	debug_cube = cube
	var verts = PackedVector3Array()
	var indices = PackedInt32Array()
	var uvs = PackedVector2Array()
	#var normals = PackedVector3Array() 
	
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	for voxel in map:
		verts.append_array(get_verts(voxel.world_position, prism_size, height, surface))
		map_dict[voxel.grid_position] = voxel

	create_uvs(uvs, map.size())
	
	var correction_passes = 0
	var faults = correct_geometry()
	while faults > 0:
		faults = correct_geometry()
		correction_passes += 1
	print(correction_passes, " passes to terrace terrain")
	
	build_geometry(indices, map.size())
	
	# Create & assign mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	#arrays[Mesh.ARRAY_NORMAL] = normals
	surface.create_from_arrays(arrays, Mesh.PRIMITIVE_TRIANGLES)
	surface.optimize_indices_for_cache()
	surface.generate_normals()
	surface.generate_tangents()
	return surface.commit()


func correct_geometry() -> int:
	##Proto-code
	var removed = 0

	for prism in map:
		if not prism.buffer:
			#if prism.grid_position.y > 0:
			prism.type = Voxel.biome.AIR
			continue
		
		if prism.type == Voxel.biome.AIR:
			continue
		# mark as air if voxel underneath is air
		var neighbor_pos : Vector3i = prism.grid_position
		neighbor_pos.y -= 1
		if neighbor_pos.y < 1:
			continue
		var bottom_neighbor : Voxel = map_dict.get(neighbor_pos)
		if bottom_neighbor:
			if bottom_neighbor.type == Voxel.biome.AIR:
				prism.type = Voxel.biome.AIR
				removed += 1
				continue

		# mark as air if diagonal voxels underneath are air
		if not WorldMap.world_settings.terrace:
			continue
		var table = WorldMap.get_tile_neighbor_table(prism.grid_position.x)
		for dir in table:
			neighbor_pos = prism.grid_position
			neighbor_pos.x += dir.x
			neighbor_pos.z += dir.y
			neighbor_pos.y -= WorldMap.world_settings.terrace_steps
			var v : Voxel = map_dict.get(neighbor_pos)
			if not v:
				if WorldMap.world_settings.terrace_edges:
					if prism.grid_position.y != 0:
						prism.type = prism.biome.AIR
						removed += 1
				continue
			#Check below
			if v.type == Voxel.biome.AIR:
				prism.type = Voxel.biome.AIR
				removed += 1
				break
				
	#print("Corrected Voxels: ", removed)
	return removed


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
		for i in range(WorldMap.HEXAGONAL_NEIGHBOR_DIRECTIONS.size()):
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
		if draw_face(top_neighbor): #if not map_dict.has(top_neighbor):
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
func get_verts(position : Vector3, size : float, height: float, surface) -> PackedVector3Array:
	var verts = PackedVector3Array()
	var top = Vector3(0.0, height, 0.0)
	
	# Append base vertices
	for v in base_vertices:
		surface.set_smooth_group(-1)
		verts.append(v * size + position)  # Base vertices

	# Append top vertices
	for v in base_vertices:
		surface.set_smooth_group(-1)
		verts.append(v * size + top + position)  # Top vertices
	
	# append top center vert
	surface.set_smooth_group(-1)
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
