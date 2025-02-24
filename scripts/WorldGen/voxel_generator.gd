class_name VoxelGenerator

const sides = 6

func generate_hex_prism(height: float) -> Mesh:
	var mesh = ArrayMesh.new()
	var verts = PackedVector3Array()
	var indices = PackedInt32Array()
	
	#var uvs = PackedVector2Array()  # Array to store UVs
	
	# Create vertices
	verts.append_array(get_verts(height))
	
	_create_side_faces(indices, verts)
	
	#_create_bottom_face(indices, verts)

	_create_top_face(indices, verts, height)
	
	#create_uvs(uvs, sides)
	
	# Create mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	#arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	return mesh


# Function to create indices for the side faces
func _create_side_faces(indices: PackedInt32Array, verts: PackedVector3Array) -> void:
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


# Function to create indices for the bottom face
func _create_bottom_face(indices: PackedInt32Array, verts: PackedVector3Array, sides: int) -> void:
	var bottom_center = verts.size()
	verts.append(Vector3(0.0, 0.0, 0.0))	# Bottom center vertex
	for i in range(sides):
		var next_i = (i + 1) % sides
		indices.append(i)					# Base vertex
		indices.append(next_i)				# Next base vertex
		indices.append(bottom_center)		# Bottom center vertex


# Function to create indices for the top face
func _create_top_face(indices: PackedInt32Array, verts: PackedVector3Array, height: float) -> void:
	var top_center = verts.size()
	verts.append(Vector3(0.0, height, 0.0)) # Top center vertex
	for i in range(sides):
		var next_i = (i + 1) % sides
		indices.append(i + sides)			# Top vertex
		indices.append(next_i + sides)		# Next top vertex
		indices.append(top_center)			# Top center vertex


func create_uvs(uvs : PackedVector2Array, sides : int):
	# Base face and top face will have similar UVs
	for i in range(sides):
		var angle = (i / float(sides)) * 2.0 * 3.14
		var u = (cos(angle) + 1.0) / 2.0  # Map from -1..1 to 0..1
		var v = (sin(angle) + 1.0) / 2.0  # Map from -1..1 to 0..1
		uvs.append(Vector2(u, v))  # Base vertices UVs
		uvs.append(Vector2(u, v))  # Top vertices UVs


# Function to get the vertices for the base and top hexagon
func get_verts(height : float) -> PackedVector3Array:
	# Define the base hexagon
	var base_vertices = [
		Vector3(0.0, 0.0, -1.0),    # Left
		Vector3(0.866, 0.0, -0.5),   # Top-left
		Vector3(0.866, 0.0, 0.5),    # Top-right
		Vector3(0.0, 0.0, 1.0),      # Right
		Vector3(-0.866, 0.0, 0.5),   # Bottom-right
		Vector3(-0.866, 0.0, -0.5)   # Bottom-left
	]

	var verts : PackedVector3Array = PackedVector3Array()
	
	# Append base vertices
	for v in base_vertices:
		verts.append(v)  # Base vertices
	
	# Append top vertices (translated upwards by height)
	for v in base_vertices:
		verts.append(v + Vector3(0.0, height, 0.0))  # Top vertices
	
	return verts
