extends Node3D
class_name Unit

@export_category("Data")
@export var unit_name : String = "Unit"
@export var max_health: int = 10
var current_health: int = 10
@export var ground_offset : float

@export_category("Movement")
@export var movement_range: int = 3
@export var max_height_movement = 1
@export var model: PackedScene

var occupied_voxel : Voxel
var team # which "team" does this unit belong to


func _ready() -> void:
	current_health = max_health


## Put this unit on a tile at position
func place_unit(new_position : Vector3, tile : VoxelCollider):
	position = new_position
	position.y += ground_offset
	leave_tile()
	occupy_tile(tile.voxel)


func occupy_tile(tile : Voxel):
	occupied_voxel = tile
	tile.occupier = self


func leave_tile():
	if occupied_voxel:
		occupied_voxel.occupier = null
