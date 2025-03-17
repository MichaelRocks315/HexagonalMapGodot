class_name Voxel
enum biome {GRASS, SAND, WATER, ICE, STONE, AIR, DEBUG}

var grid_position_xyz : Vector3i
var grid_position_xz : Vector2i

var world_position : Vector3
var type : biome
var noise : float
var buffer : bool = false
var water : bool = false
var air_probability : float = 0

var neighbors = []
var placeable = true
var occupier : Unit
var collider
