extends Resource
class_name GenerationSettings

enum shape {HEXAGONAL, RECTANGULAR, DIAMOND, CIRCLE}

@export_category("Voxel")
var tile_size : float = 1 #Size scalar
@export var map_shape : shape = shape.HEXAGONAL
@export_range(0, 99, 1) var radius: int = 5
@export_range(1, 20, 1) var max_height: int = 3
@export var noise : FastNoiseLite

@export var terrace = true
@export var terrace_edges = false

@export var map_seed : int

@export_category("Villages")
@export var spawn_villages = true
@export var map_edge_buffer = 2
@export_range(1, 99) var spacing = 6
