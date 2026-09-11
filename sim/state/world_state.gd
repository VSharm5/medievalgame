extends RefCounted
class_name WorldState

## Canonical world vocabulary (SPEC §39). Structure only — no solver/ledger/
## tick logic, no tuning values. Field names are normative (AGENTS.md §6/§7).

var world_id: String
var world_name: String

var simulation_year: int
var simulation_month: int

var paused: bool = true
var speed: float = 1.0

var map_asset: String
var simulation_grid: Vector2i

var settlements: Array[SettlementState] = []
var trade_routes: Array[TradeRoute] = []
# SPEC §25: "one or more external-market reservoir nodes."
var external_economy: Array[ExternalMarket] = []

# Recommendation Engine (SPEC §26) record is out of scope for this task;
# left as an untyped-element Array placeholder until that type exists.
var recommendations: Array = []

var economic_version: int = 0

# Reserved, unused in V1 (SPEC §7, §39).
var random_seed: int = 0
