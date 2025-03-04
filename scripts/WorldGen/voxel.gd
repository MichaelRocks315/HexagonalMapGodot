class_name Voxel
enum biome {GRASS, SAND, WATER, ICE, STONE, AIR}

var grid_position : Vector3i
var world_position : Vector3
var type : biome
var noise : float
var buffer : bool = false
var water : bool = false

var neighbors = []
var placeable = true
#var occupier : Unit
