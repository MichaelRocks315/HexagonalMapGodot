extends Resource
class_name GenerationSettings

enum shape {HEXAGONAL, RECTANGULAR, DIAMOND, CIRCLE}

@export_category("Tiles")
@export var tiles : Array[Biome]
var tile_size : float = 1 #Scalar for different size tiles, leave at 1 if not using your own mesh
@export var debug = false

@export_category("Generation")
@export var map_seed : int
@export var map_shape : shape = shape.HEXAGONAL
@export_range(0, 99, 1) var radius: int = 5
@export_range(1, 20, 1) var max_height: int = 3
@export var biome_noise : FastNoiseLite


@export_category("Villages")
@export var spawn_villages = true
@export var map_edge_buffer = 2
@export_range(1, 99) var spacing = 6
