extends RefCounted
class_name Tunables

## All non-resource, non-echelon constants (SPEC §50). Central config — the
## single source of tuning truth (ARCHITECTURE.md §6). No tuning literal may
## appear anywhere else. Raw values + direct lookups only; no formulas.

# SPEC §50 — exact, law. Subject to the §25 faucet-open constraint when used.
const EXTERNAL_EXPORT_PRICE_FACTOR: float = 0.75
const EXTERNAL_IMPORT_PRICE_FACTOR: float = 1.25

# SPEC §8, §50 — exact, law. 256x128 cells for ~2048x1024 source art.
const DEFAULT_SIMULATION_GRID: Vector2i = Vector2i(256, 128)

# PLACEHOLDER, unvalidated, calibrate vs §45
const DISCRETIONARY_RATE: float = 0.2
# PLACEHOLDER, unvalidated, calibrate vs §45
const RESERVE_MONTHS: float = 3.0
# PLACEHOLDER, unvalidated, calibrate vs §45
const ENTERTAINMENT_DISTANCE_DECAY_K: float = 0.1
# PLACEHOLDER, unvalidated, calibrate vs §45
const TRANSPORT_COST_CONSTANT: float = 0.01
# PLACEHOLDER, unvalidated, calibrate vs §45
const FOREIGN_VISITOR_DEMAND: float = 100.0
# PLACEHOLDER, unvalidated, calibrate vs §45
const EXTERNAL_MARKET_ACCESSIBILITY: float = 1.0

# PLACEHOLDER, unvalidated, calibrate vs §45 — same value for every resource.
const PRODUCTIVITY_CONSTANT: Dictionary[SimEnums.ResourceType, float] = {
	SimEnums.ResourceType.FOOD: 1.0,
	SimEnums.ResourceType.WATER: 1.0,
	SimEnums.ResourceType.WOOD: 1.0,
	SimEnums.ResourceType.METAL: 1.0,
	SimEnums.ResourceType.STONE: 1.0,
	SimEnums.ResourceType.WINE: 1.0,
	SimEnums.ResourceType.LUXURY_GOODS: 1.0,
}


static func productivity_constant(resource: SimEnums.ResourceType) -> float:
	return PRODUCTIVITY_CONSTANT[resource]
