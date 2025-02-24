class_name VoxelGenerator

const sides = 6

func generate_hex_prism(height: float) -> Mesh:
	var mesh = ArrayMesh.new()
	var verts = PackedVector3Array()
	var indices = PackedInt32Array()
	var uvs = PackedVector2Array()  # Array to store UVs
	var normals = PackedVector3Array()  # Array to store normals
	
	# Create vertices, indicies, normals and uvs
	verts.append_array(get_verts(height))
	_create_side_faces(indices, verts, normals)
	_create_top_face(indices, verts, height, normals)
	create_uvs(uvs, verts.size())
	
	# Debugging: Print array sizes
	print("Vertices: ", verts.size())
	print("Indices: ", indices.size())
	print("Normals: ", normals.size())
	print("UVs: ", uvs.size())
	
	# Create mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	return mesh


# Function to create indices for the side faces and calculate normals
func _create_side_faces(indices: PackedInt32Array, verts: PackedVector3Array, normals: PackedVector3Array) -> void:
	for i in range(sides):
		var next_i = (i + 1) % sides
		# First triangle of the quad (base to top)
		indices.append(i)			# Base vertex
		indices.append(next_i)		# Next base vertex
		indices.append(i + sides)	# Top vertex
		
		# Second triangle of the quad (top to next base)
		indices.append(next_i)			# Next base vertex
		indices.append(next_i + sides)	# Next top vertex
		indices.append(i + sides)		# Top vertex
		
		# Calculate normals for the side faces
		var normal = (verts[next_i] - verts[i]).cross(verts[i + sides] - verts[i]).normalized()
		normals.append(normal)


# Function to create indices for the top face and calculate normals
func _create_top_face(indices: PackedInt32Array, verts: PackedVector3Array, height: float, normals: PackedVector3Array) -> void:
	var top_center = verts.size()
	verts.append(Vector3(0.0, height, 0.0)) # Top center vertex
	var normal = Vector3(0.0, 1.0, 0.0)
	normals.append(normal)
	for i in range(sides):
		var next_i = (i + 1) % sides
		#Add triangles
		indices.append(i + sides)			# Top vertex
		indices.append(next_i + sides)		# Next top vertex
		indices.append(top_center)			# Top center vertex
		# Add normals for the top verticies
		normals.append(normal)


# Function to create UVs
func create_uvs(uvs: PackedVector2Array, vertex_count: int) -> void:
	for i in range(vertex_count):
		# Simple UV mapping: stretch the texture evenly across the prism
		var u = float(i % sides) / float(sides)
		var v = float(i / sides) / 2.0  # Base and top vertices
		uvs.append(Vector2(u, v))


# Function to get the vertices for the base and top hexagon
func get_verts(height: float) -> PackedVector3Array:
	# Define the base hexagon
	var base_vertices = [
		Vector3(0.0, 0.0, -1.0),    # Left
		Vector3(0.866, 0.0, -0.5),   # Top-left
		Vector3(0.866, 0.0, 0.5),    # Top-right
		Vector3(0.0, 0.0, 1.0),      # Right
		Vector3(-0.866, 0.0, 0.5),   # Bottom-right
		Vector3(-0.866, 0.0, -0.5)   # Bottom-left
	]

	var verts = PackedVector3Array()
	
	# Append base vertices
	for v in base_vertices:
		verts.append(v)  # Base vertices
	
	# Append top vertices (translated by height)
	for v in base_vertices:
		verts.append(v + Vector3(0.0, height, 0.0))  # Top vertices
	
	return verts
