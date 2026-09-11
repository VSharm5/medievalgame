extends RefCounted
class_name EchelonConfig

## Echelon definitions (SPEC §14, §19, §23, §50): workforce, base attraction,
## base export/service capacity, mandatory-resource set. Central config —
## the single source of tuning truth (ARCHITECTURE.md §6). No tuning literal
## may appear anywhere else. Raw values + direct lookups only; no formulas
## (workforce_factor, market_factor, attractiveness, etc. are later tasks).

# SPEC §14, §50 — exact, law.
const WORKFORCE: Dictionary[SimEnums.Echelon, float] = {
	SimEnums.Echelon.HAMLET: 100.0,
	SimEnums.Echelon.VILLAGE: 500.0,
	SimEnums.Echelon.TOWN: 2000.0,
	SimEnums.Echelon.WALLED_CITY: 10000.0,
	SimEnums.Echelon.CAPITAL_TIER: 25000.0,
}

# SPEC §19, §50 — exact, law.
const BASE_ATTRACTION: Dictionary[SimEnums.Echelon, float] = {
	SimEnums.Echelon.HAMLET: 0.1,
	SimEnums.Echelon.VILLAGE: 0.3,
	SimEnums.Echelon.TOWN: 0.6,
	SimEnums.Echelon.WALLED_CITY: 1.0,
	SimEnums.Echelon.CAPITAL_TIER: 1.5,
}

# PLACEHOLDER, unvalidated, calibrate vs §45
const BASE_CAPACITY: Dictionary[SimEnums.Echelon, float] = {
	SimEnums.Echelon.HAMLET: 50.0,
	SimEnums.Echelon.VILLAGE: 200.0,
	SimEnums.Echelon.TOWN: 800.0,
	SimEnums.Echelon.WALLED_CITY: 3000.0,
	SimEnums.Echelon.CAPITAL_TIER: 6000.0,
}

# seeded assumption, SPEC §13 leaves the boundary open
# (Dictionary value type is untyped Array — Godot 4.7 does not support
# nested typed collections, i.e. Dictionary[K, Array[V]]. mandatory_resources()
# below returns a properly typed Array[SimEnums.ResourceType].)
const MANDATORY_RESOURCES: Dictionary[SimEnums.Echelon, Array] = {
	SimEnums.Echelon.HAMLET: [
		SimEnums.ResourceType.FOOD, SimEnums.ResourceType.WATER, SimEnums.ResourceType.WOOD,
	],
	SimEnums.Echelon.VILLAGE: [
		SimEnums.ResourceType.FOOD, SimEnums.ResourceType.WATER, SimEnums.ResourceType.WOOD,
	],
	SimEnums.Echelon.TOWN: [
		SimEnums.ResourceType.FOOD, SimEnums.ResourceType.WATER, SimEnums.ResourceType.WOOD,
		SimEnums.ResourceType.METAL,
	],
	SimEnums.Echelon.WALLED_CITY: [
		SimEnums.ResourceType.FOOD, SimEnums.ResourceType.WATER, SimEnums.ResourceType.WOOD,
		SimEnums.ResourceType.METAL, SimEnums.ResourceType.STONE,
	],
	SimEnums.Echelon.CAPITAL_TIER: [
		SimEnums.ResourceType.FOOD, SimEnums.ResourceType.WATER, SimEnums.ResourceType.WOOD,
		SimEnums.ResourceType.METAL, SimEnums.ResourceType.STONE,
	],
}


static func workforce(echelon: SimEnums.Echelon) -> float:
	return WORKFORCE[echelon]


static func base_attraction(echelon: SimEnums.Echelon) -> float:
	return BASE_ATTRACTION[echelon]


static func base_capacity(echelon: SimEnums.Echelon) -> float:
	return BASE_CAPACITY[echelon]


static func mandatory_resources(echelon: SimEnums.Echelon) -> Array[SimEnums.ResourceType]:
	var typed: Array[SimEnums.ResourceType] = []
	typed.assign(MANDATORY_RESOURCES[echelon])
	return typed
