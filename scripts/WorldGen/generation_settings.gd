extends Resource
class_name GenerationSettings

enum shape {HEXAGONAL, RECTANGULAR, DIAMOND, CIRCLE}

@export_category("Voxel")
var tile_size : float = 1 #Size scalar
@export var map_shape : shape = shape.HEXAGONAL
@export_range(0, 99, 1) var radius: int = 5
@export_range(1, 20, 1) var max_height: int = 3
@export var material : Material
@export var noise : FastNoiseLite

@export_range(0, 4) var terrace_steps = 1
@export var flat_buffer = true

@export var map_seed : int

@export_category("Villages")
@export var spawn_villages = true
@export var map_edge_buffer = 2
@export_range(1, 99) var spacing = 6
