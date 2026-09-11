extends RefCounted
class_name ResourceFields

## Per-cell environmental fields and per-resource potential (SPEC §10, §11).
## Structure only — no world-evaluator logic (that is sim/solver/world_evaluator.gd,
## a later task). Arrays/data, never one node per cell (SPEC §46).

var grid_width: int = 0
var grid_height: int = 0

# Per-cell continuous environmental fields (SPEC §10).
var moisture: PackedFloat32Array = PackedFloat32Array()
var fertility: PackedFloat32Array = PackedFloat32Array()
var forestability: PackedFloat32Array = PackedFloat32Array()
var rockiness: PackedFloat32Array = PackedFloat32Array()
var mineralization: PackedFloat32Array = PackedFloat32Array()
var dryness: PackedFloat32Array = PackedFloat32Array()
var elevation: PackedFloat32Array = PackedFloat32Array()

# Per-cell, per-resource potential_r(c) grids (SPEC §11).
var potential: Dictionary[SimEnums.ResourceType, PackedFloat32Array] = {
	SimEnums.ResourceType.FOOD: PackedFloat32Array(),
	SimEnums.ResourceType.WATER: PackedFloat32Array(),
	SimEnums.ResourceType.WOOD: PackedFloat32Array(),
	SimEnums.ResourceType.METAL: PackedFloat32Array(),
	SimEnums.ResourceType.STONE: PackedFloat32Array(),
	SimEnums.ResourceType.WINE: PackedFloat32Array(),
	SimEnums.ResourceType.LUXURY_GOODS: PackedFloat32Array(),
}
