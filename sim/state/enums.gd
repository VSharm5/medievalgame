extends RefCounted
class_name SimEnums

## Shared enum/type-constants for sim/state canonical structures.
## Structural only — no tuning values (those live in sim/config, task 0.3).

# SPEC §13: Hamlet -> Village -> Town -> Walled City -> Capital-tier.
enum Echelon {
	HAMLET,
	VILLAGE,
	TOWN,
	WALLED_CITY,
	CAPITAL_TIER,
}

# SPEC §12 resource set.
enum ResourceType {
	FOOD,
	WATER,
	WOOD,
	METAL,
	STONE,
	WINE,
	LUXURY_GOODS,
}

# SPEC §29 Transaction.type.
enum TransactionType {
	GOODS_DOMESTIC,
	GOODS_EXTERNAL,
	SERVICE_DOMESTIC,
	SERVICE_FOREIGN,
	TRANSPORT,
}

# SPEC §22 TradeEndpoint.type.
enum EndpointType {
	SETTLEMENT,
	EXTERNAL_MARKET,
}

# All ResourceType values, in enum declaration order — used to zero-fill
# per-resource dictionaries so every settlement carries a complete key set
# (SPEC §7 stable-ID ordering; no missing keys).
const ALL_RESOURCE_TYPES: Array[ResourceType] = [
	ResourceType.FOOD,
	ResourceType.WATER,
	ResourceType.WOOD,
	ResourceType.METAL,
	ResourceType.STONE,
	ResourceType.WINE,
	ResourceType.LUXURY_GOODS,
]
