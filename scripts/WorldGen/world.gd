extends Node

#var map : Array[Tile]
var map_as_dict : Dictionary = {}
var is_map_staggered = false

## Shorthand for different layout/neighbor configurations depending on map-shape and stagger
const HEXAGONAL_NEIGHBOR_DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, -1),  # Face 0: Top-Right → NE
	Vector2i(1, 0),   # Face 1: Right → E
	Vector2i(0, 1),   # Face 2: Bottom-Right → SE
	Vector2i(-1, 1),  # Face 3: Bottom-Left → SW
	Vector2i(-1, 0),  # Face 4: Left → W
	Vector2i(0, -1)   # Face 5: Top-Left → NW
]
const NEIGHBOR_DIRECTIONS_EVEN: Array[Vector2i] = [
	# For even rows (x % 2 == 0)
	Vector2i(1, -1),  # Northeast
	Vector2i(1, 0),   # East
	Vector2i(0, 1),   # Southeast
	Vector2i(-1, 0),  # Southwest
	Vector2i(-1, -1), # Northwest
	Vector2i(0, -1)   # West
]
const NEIGHBOR_DIRECTIONS_ODD: Array[Vector2i] = [
	# For odd rows (x % 2 == 1)
	Vector2i(1, 0),   # Northeast
	Vector2i(1, 1),   # East
	Vector2i(0, 1),   # Southeast
	Vector2i(-1, 1),  # Southwest
	Vector2i(-1, 0),  # Northwest
	Vector2i(0, -1)   # West
]
var neighbor_positions = HEXAGONAL_NEIGHBOR_DIRECTIONS

# Distances to neighbors assuming tile_size of 1
#const NEIGHBOR_WORLD_OFFSET = [
	#Vector3(0, 0, -1),        # Top
	#Vector3(0.866, 0, -0.5),  # Top-right
	#Vector3(0.866, 0, 0.5),   # Bottom-right
	#Vector3(0, 0, 1),         # Bottom
	#Vector3(-0.866, 0, 0.5),  # Bottom-left
	#Vector3(-0.866, 0, -0.5)  # Top-left
#]


func set_map(all_tiles):
	#map = all_tiles
	for t in all_tiles:
		map_as_dict[Vector2(t.pos_data.grid_position.x, t.pos_data.grid_position.y)] = t


## Handy function for finding all neigbors of a tile
#func get_tile_neighbors(tile : Tile) -> Array[Tile]:
	#var neighbors : Array[Tile] = []
	#if is_map_staggered:
		#if tile.pos_data.grid_position.x % 2 == 0:
			#neighbor_positions = NEIGHBOR_DIRECTIONS_EVEN
		#else:
			#neighbor_positions = NEIGHBOR_DIRECTIONS_ODD
			#
	#for direction in neighbor_positions:
		#var neighbor_coords = Vector2(tile.pos_data.grid_position.x + int(direction.x), tile.pos_data.grid_position.y + int(direction.y)) 
		#if neighbor_coords in map_as_dict:
			#neighbors.append(map_as_dict[neighbor_coords])
	#return neighbors


func get_tile_neighbor_table(row) -> Array[Vector2i]:
	if is_map_staggered:
		if row % 2 == 0:
			return NEIGHBOR_DIRECTIONS_EVEN
		else:
			return NEIGHBOR_DIRECTIONS_ODD
	return HEXAGONAL_NEIGHBOR_DIRECTIONS
