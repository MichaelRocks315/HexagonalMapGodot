class_name VoxelGenerator

const sides = 6

func generate_chunk(map : MappingData, radius, prism_size : float, height: float) -> Mesh:
	
	var verts = PackedVector3Array()
	var indices = PackedInt32Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array() 
	
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_color(Color.ORANGE_RED)

	var hex_width = sqrt(3) * prism_size  # Horizontal distance between hexagons
	var hex_height = 1.5 * prism_size  # Vertical distance between hexagons

	# Generate verticies
	for col in range(radius):
		for row in range(radius):
			var x_offset = col * hex_width
			var z_offset = row * hex_height
			if row % 2 != 0:
				x_offset += hex_width / 2
			var next_position = Vector3(x_offset, 0, z_offset)
			verts.append_array(get_verts(next_position, prism_size, height))
	
	# Generate indices
	build_geometry(verts, indices, normals, radius * radius)
	
	# Create & assign mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	surface.create_from_arrays(arrays, Mesh.PRIMITIVE_TRIANGLES)
	surface.generate_normals(false)
	return surface.commit()

func build_geometry(verts: PackedVector3Array, indices: PackedInt32Array, normals: PackedVector3Array, prism_count: int):
	# Construct edges and faces
	for prism in range(prism_count):
		var first_prism_vert = prism * 13  # Each prism has 13 vertices
		
		## Construct sides
		for i in range(sides):
			var bottom_vert = first_prism_vert + i
			var next_bottom_vert = first_prism_vert + ((i + 1) % sides)
			var top_vert = first_prism_vert + 6 + i
			var next_top_vert = first_prism_vert + 6 + ((i + 1) % sides)
			
			# First triangle of the quad (base to top)
			indices.append(bottom_vert)        # Bottom vertex
			indices.append(next_bottom_vert)   # Next bottom vertex
			indices.append(top_vert)           # Top vertex
			
			# Second triangle of the quad (top to next base)
			indices.append(next_bottom_vert)   # Next bottom vertex
			indices.append(next_top_vert)      # Next top vertex
			indices.append(top_vert)           # Top vertex
			
			# Calculate normals for the side faces
			#var normal = (verts[next_bottom_vert] - verts[bottom_vert]).cross(verts[top_vert] - verts[bottom_vert]).normalized()
			#normals.append(normal)
		
		## Construct top
		var top_center_vert = first_prism_vert + 12  # Index of the top center vertex
		for i in range(sides):
			var top_vert = first_prism_vert + 6 + i
			var next_top_vert = first_prism_vert + 6 + ((i + 1) % sides)
			
			# Add triangles for the top face
			indices.append(top_vert)           # Top vertex
			indices.append(next_top_vert)      # Next top vertex
			indices.append(top_center_vert)    # Top center vertex
			
			# Calculate normals for the top face
			#var normal = (verts[next_top_vert] - verts[top_vert]).cross(verts[top_center_vert] - verts[top_vert]).normalized()
			#normals.append(normal)
#func build_geometry(verts: PackedVector3Array, indices: PackedInt32Array, normals: PackedVector3Array, prism_count : int):
	##construct edges and faces
	#for prism in range(prism_count):
	### Construct sides
		#for i in range(sides):
			#var first_prism_vert = prism * 14
			#var index = i + first_prism_vert
			#var next_i = (i + 1) % sides + first_prism_vert
			## First triangle of the quad (base to top)
			#indices.append(index)			# Base vertex
			#indices.append(next_i)		# Next base vertex
			#indices.append(index + sides)	# Top vertex
			## Second triangle of the quad (top to next base)
			#indices.append(next_i)			# Next base vertex
			#indices.append(next_i + sides + prism)	# Next top vertex
			#indices.append(index + sides)		# Top vertex
			## Calculate normals for the side faces
			##var normal = (verts[next_i + prism] - verts[index]).cross(verts[index + sides] - verts[index]).normalized()
			##normals.append(normal)
	### Construct top
		#
		#for i in range(sides):
			#var first_prism_vert = prism * 14
			#var index = i  + 6 + first_prism_vert
			#var next_i = (index + 1) % sides + first_prism_vert
			#var center_vert = first_prism_vert + 6
			##Add triangles
			#indices.append(index + sides)			# Top vertex
			#indices.append(next_i + sides)		# Next top vertex
			#indices.append(center_vert)			# Top center vertex
			## Add normals for the top verticies
			##normal = (verts[next_i] - verts[index]).cross(verts[index + sides] - verts[index]).normalized()
			##normals.append(normal)


# Function to create indices for the side faces and calculate normals
func create_side_faces(indices: PackedInt32Array, verts: PackedVector3Array, normals: PackedVector3Array) -> void:
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
func create_top_face(indices: PackedInt32Array, verts: PackedVector3Array, height: float, normals: PackedVector3Array) -> void:
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
		normal = (verts[next_i] - verts[i]).cross(verts[i + sides] - verts[i]).normalized()
		normals.append(normal)


# Function to create UVs
func create_uvs(uvs: PackedVector2Array, verts: int) -> void:
	for i in range(sides):
		var angle = (float(i) / float(sides)) * 2.0 * PI
		var u = 0.5 + 0.5 * cos(angle)  # Map to 0..1 range
		uvs.append(Vector2(u, 0.0))  # Bottom vertex UV

	for i in range(sides):
		var angle = (float(i) / float(sides)) * 2.0 * PI
		var u = 0.5 + 0.5 * cos(angle)  # Map to 0..1 range
		var v = 0.5 + 0.5 * sin(angle)  # Map to 0..1 range
		uvs.append(Vector2(u, v))  # Top face vertex UV
		
	# Top center vertex UV
	uvs.append(Vector2(0.5, 0.5))  # Center of the top face


# Function to get the vertices for the base and top hexagon
func get_verts(position : Vector3, size : float, height: float) -> PackedVector3Array:
	# Define the base hexagon
	var base_vertices = [
		Vector3(0.0, 0.0, -size),    # Left
		Vector3(size * 0.866, 0.0, -size * 0.5),   # Top-left
		Vector3(size * 0.866, 0.0, size * 0.5),    # Top-right
		Vector3(0.0, 0.0, size),      # Right
		Vector3(size * -0.866, 0.0, size * 0.5),   # Bottom-right
		Vector3(size * -0.866, 0.0, size * -0.5)   # Bottom-left
	]

	var verts = PackedVector3Array()
	
	# Append base vertices
	for v in base_vertices:
		verts.append(v + position)  # Base vertices
	
	# Append top vertices (translated by height)
	for v in base_vertices:
		verts.append(v + Vector3(0.0, height, 0.0) + position)  # Top vertices
	
	verts.append(position + Vector3(0.0, height, 0.0)) # Top center vertex
	
	return verts
