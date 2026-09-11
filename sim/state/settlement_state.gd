extends RefCounted
class_name SettlementState

## Canonical settlement vocabulary (SPEC §38, AGENTS.md §7). Structure only —
## no solver/ledger/tick logic, no tuning values. Field names are normative;
## do not rename, abbreviate, or introduce synonyms (AGENTS.md §6).

## Per-resource mandatory-need status (SPEC §16, §37). Minimal factual data:
## whether this month's mandatory consumption is covered, and the projected
## stockpile runway. INF means "not depleting" (SPEC §33 convention). This is
## a separate, per-resource concept from the settlement-wide Healthy/
## Strained/Critical/Failed/Recovery state of SPEC §37, which is not stored
## here.
class MandatoryStatus extends RefCounted:
	var covered: bool = false
	var months_to_zero: float = INF

var id: String
var name: String
var map_position: Vector2

var echelon: SimEnums.Echelon
var is_kingdom_capital: bool = false

var nominal_workforce: float
var productive_workforce: float

var wealth: float
var wealth_delta_month: float

# Per-resource quantities (SPEC §17 stockpile formula). Every ResourceType is
# present with a 0.0 default — no missing keys (SPEC §7 stable-ID ordering).
var stockpiles: Dictionary[SimEnums.ResourceType, float] = {
	SimEnums.ResourceType.FOOD: 0.0,
	SimEnums.ResourceType.WATER: 0.0,
	SimEnums.ResourceType.WOOD: 0.0,
	SimEnums.ResourceType.METAL: 0.0,
	SimEnums.ResourceType.STONE: 0.0,
	SimEnums.ResourceType.WINE: 0.0,
	SimEnums.ResourceType.LUXURY_GOODS: 0.0,
}
var production_rates: Dictionary[SimEnums.ResourceType, float] = {
	SimEnums.ResourceType.FOOD: 0.0,
	SimEnums.ResourceType.WATER: 0.0,
	SimEnums.ResourceType.WOOD: 0.0,
	SimEnums.ResourceType.METAL: 0.0,
	SimEnums.ResourceType.STONE: 0.0,
	SimEnums.ResourceType.WINE: 0.0,
	SimEnums.ResourceType.LUXURY_GOODS: 0.0,
}
var consumption_rates: Dictionary[SimEnums.ResourceType, float] = {
	SimEnums.ResourceType.FOOD: 0.0,
	SimEnums.ResourceType.WATER: 0.0,
	SimEnums.ResourceType.WOOD: 0.0,
	SimEnums.ResourceType.METAL: 0.0,
	SimEnums.ResourceType.STONE: 0.0,
	SimEnums.ResourceType.WINE: 0.0,
	SimEnums.ResourceType.LUXURY_GOODS: 0.0,
}
var imports: Dictionary[SimEnums.ResourceType, float] = {
	SimEnums.ResourceType.FOOD: 0.0,
	SimEnums.ResourceType.WATER: 0.0,
	SimEnums.ResourceType.WOOD: 0.0,
	SimEnums.ResourceType.METAL: 0.0,
	SimEnums.ResourceType.STONE: 0.0,
	SimEnums.ResourceType.WINE: 0.0,
	SimEnums.ResourceType.LUXURY_GOODS: 0.0,
}
var exports: Dictionary[SimEnums.ResourceType, float] = {
	SimEnums.ResourceType.FOOD: 0.0,
	SimEnums.ResourceType.WATER: 0.0,
	SimEnums.ResourceType.WOOD: 0.0,
	SimEnums.ResourceType.METAL: 0.0,
	SimEnums.ResourceType.STONE: 0.0,
	SimEnums.ResourceType.WINE: 0.0,
	SimEnums.ResourceType.LUXURY_GOODS: 0.0,
}

# Monetary components (SPEC §38 — standardized vocabulary, no synonyms).
var domestic_goods_revenue: float
var domestic_goods_import_cost: float
var domestic_service_income: float
var domestic_service_spending: float
var external_export_revenue: float
var external_import_cost: float
var foreign_visitor_income: float
var transport_cost_paid: float

var mandatory_status: Dictionary[SimEnums.ResourceType, MandatoryStatus] = {
	SimEnums.ResourceType.FOOD: MandatoryStatus.new(),
	SimEnums.ResourceType.WATER: MandatoryStatus.new(),
	SimEnums.ResourceType.WOOD: MandatoryStatus.new(),
	SimEnums.ResourceType.METAL: MandatoryStatus.new(),
	SimEnums.ResourceType.STONE: MandatoryStatus.new(),
	SimEnums.ResourceType.WINE: MandatoryStatus.new(),
	SimEnums.ResourceType.LUXURY_GOODS: MandatoryStatus.new(),
}
# Per-resource wants satisfaction fraction in [0.0, 1.0] (SPEC §16, §19
# wants_satisfaction).
var wants_status: Dictionary[SimEnums.ResourceType, float] = {
	SimEnums.ResourceType.FOOD: 0.0,
	SimEnums.ResourceType.WATER: 0.0,
	SimEnums.ResourceType.WOOD: 0.0,
	SimEnums.ResourceType.METAL: 0.0,
	SimEnums.ResourceType.STONE: 0.0,
	SimEnums.ResourceType.WINE: 0.0,
	SimEnums.ResourceType.LUXURY_GOODS: 0.0,
}

var export_capacity: float
var export_capacity_used: float
var service_capacity: float
var service_utilization: float
var attractiveness: float
var traffic: float
var disposable_income: float
var discretionary_budget: float
var catchment_radius: float
var projected_treasury_zero: float
