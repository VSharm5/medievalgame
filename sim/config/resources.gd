extends RefCounted
class_name ResourceConfig

## Resource definitions (SPEC §12): base_price, transport_burden. Central
## config — the single source of tuning truth (ARCHITECTURE.md §6). No
## tuning literal may appear anywhere else. Raw values + direct lookups
## only; computed pricing (get_price / get_external_*_price, SPEC §28) is a
## later task in sim/pricing.gd, not here.

# starting value, calibrate vs §45
# Value and transport burden are independent (SPEC §12) — this table is
# ordered by ascending base_price to make that independence visible against
# TRANSPORT_BURDEN below, which is ordered the opposite way.
const BASE_PRICE: Dictionary[SimEnums.ResourceType, float] = {
	SimEnums.ResourceType.WATER: 1.0,
	SimEnums.ResourceType.FOOD: 2.0,
	SimEnums.ResourceType.WOOD: 2.5,
	SimEnums.ResourceType.STONE: 4.0,
	SimEnums.ResourceType.METAL: 8.0,
	SimEnums.ResourceType.WINE: 10.0,
	SimEnums.ResourceType.LUXURY_GOODS: 50.0,
}

# starting value, calibrate vs §45
const TRANSPORT_BURDEN: Dictionary[SimEnums.ResourceType, float] = {
	SimEnums.ResourceType.WATER: 10.0,
	SimEnums.ResourceType.STONE: 8.0,
	SimEnums.ResourceType.WOOD: 6.0,
	SimEnums.ResourceType.FOOD: 4.0,
	SimEnums.ResourceType.METAL: 2.0,
	SimEnums.ResourceType.WINE: 2.0,
	SimEnums.ResourceType.LUXURY_GOODS: 0.3,
}


static func base_price(resource: SimEnums.ResourceType) -> float:
	return BASE_PRICE[resource]


static func transport_burden(resource: SimEnums.ResourceType) -> float:
	return TRANSPORT_BURDEN[resource]
