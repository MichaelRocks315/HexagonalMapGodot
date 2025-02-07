extends Node3D
class_name Tile

enum biome_type {Grassland, Forest, Desert, Ocean, Tundra, Mountain}
var mesh_data : TileMeshData
var pos_data : PositionData
var neighbors = []#Array[Tile]
var occupier : Unit
var debug_label : Label3D
var biome : String
