extends Node

# Dependencies
@export var settings : GenerationSettings
@export_category("Dependencies")
@export var object_placer : ObjectPlacer

const COLLIDER_SCRIPT = preload("res://scripts/WorldGen/Voxel/voxel_collider.gd")
const V_COLLIDER = preload("res://assets/Meshes/Tiles/HexTileCollider.tscn")

# Test-only!
@export var pfinder : Pathfinder
@export var unit1 : PackedScene
@export var unit2 : PackedScene


## Starting point: Generate a random seed, create the tiles, place POI's
func _ready() -> void:
	init_seed()
	generate_world()
	create_starting_units(floor(settings.radius/2))  ## prototyping pathfinding and units


# Randomize if no seed has been set
func init_seed():
	WorldMap.world_settings = settings
	if settings.map_seed == 0 or settings.map_seed == null:
		print("Randomizing seed")
		settings.noise.seed = randi() #New map_seed for this generation
	else:
		settings.noise.seed = settings.map_seed


## placeholder functionality for placing units onto the map
func create_starting_units(count : int):
	var safety_count = 0 #Add safety counter in case no valid tiles
	## Test pathfinder
	while count > 0 and safety_count < 50:
		var voxel : Voxel = WorldMap.top_layer_voxels.pick_random()
		if voxel.type == Voxel.biome.WATER or voxel.occupier != null:
			safety_count += 1
			continue
		var r = randf()
		
		var unit : Unit = unit1.instantiate() if r < 0.5 else unit2.instantiate()
		add_child(unit)
		unit.place_unit(voxel.world_position, voxel.collider)
		count -= 1


## Start of world_generation, time each step
func generate_world():
	var starttime = Time.get_ticks_msec()
	var interval = {"Start of Generation!" : starttime}
	
	## Get all positions through the gridmapper
	var mapper = GridMapper.new()
	var voxels : Array[Voxel] = mapper.calculate_map_positions()
	interval["Calculate Map Positions -- "] = Time.get_ticks_msec()
	
	var vg = VoxelGenerator.new()
	var chunk = vg.generate_chunk(voxels, interval)
	var mesh = MeshInstance3D.new()
	mesh.material_override = settings.material
	mesh.mesh = chunk
	add_child(mesh)
	interval["Create Voxel Mesh -- "] = Time.get_ticks_msec()
	
	if settings.debug:
		mesh.create_debug_tangents()
	
	WorldMap.set_map(vg.top_voxels)
	init_voxels(vg.top_voxels)
	interval["Generate Colliders and neighbors -- "] = Time.get_ticks_msec()

	### Spawn villages
	if settings.spawn_villages:
		var placeable = get_placeable_voxels()
		object_placer.place_villages(placeable, settings.spacing)
		interval["Spawn Villages -- "] = Time.get_ticks_msec()
	

	print_generation_results(starttime, interval)


## This mess of a function loops through the timing results of generate_world and prints them
func print_generation_results(start : float, dict : Dictionary):
	print("\n")
	var last_val = start
	var total = 0
	for key in dict:
		var val = dict[key]
		if val == start:
			print(key)
			continue
		var passed = val - last_val
		print(key, str(passed) + "ms")
		last_val = val
		total += passed
	var s = "ms"
	if total > 999: 
		s = "s"
		total *= 0.001
	print("Total completion time: ", total, s)


## Ignore buffer and ocean to return for object placer
func get_placeable_voxels() -> Array[Voxel]:
	var placeable_tiles : Array[Voxel] = []
	for voxel : Voxel in WorldMap.top_layer_voxels:
		if voxel.buffer or not voxel.placeable:
			continue
		placeable_tiles.append(voxel)
	print(str(placeable_tiles.size()) + " placeable tiles")
	return placeable_tiles


func init_voxels(valid_voxels):
	for voxel : Voxel in valid_voxels:
		# set neighbors
		var table = WorldMap.get_tile_neighbor_table(voxel.grid_position_xyz.x)
		for dir in table:
			var neighbor_pos = Vector2i(voxel.grid_position_xz.x + dir.x, voxel.grid_position_xz.y + dir.y)
			var neighbor = WorldMap.map_as_dict.get(neighbor_pos)
			if neighbor:
				voxel.neighbors.append(WorldMap.map_as_dict[neighbor_pos])
		
		#Add and setup colliders
		var c = V_COLLIDER.instantiate()
		c.position = voxel.world_position
		c.position.y += settings.voxel_height
		add_child(c)
		c.scale_object_local(Vector3(settings.voxel_size, 1, settings.voxel_size))
		c.set_script(COLLIDER_SCRIPT)
		c.add_to_group("voxels")
		c.voxel = voxel
		voxel.collider = c
		
