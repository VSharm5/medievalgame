extends RefCounted
class_name TradeRoute

## Canonical trade route vocabulary (SPEC §22, §40). Structure only — no
## solver/ledger/tick logic, no tuning values. `nodes[]` are presentation-only
## and never affect economic distance, transport cost, viability, or wealth.

class TradeEndpoint extends RefCounted:
	var type: SimEnums.EndpointType
	var id: String

class CargoItem extends RefCounted:
	var resource: SimEnums.ResourceType
	var quantity_per_month: float

var id: String
var source_endpoint: TradeEndpoint
var destination_endpoint: TradeEndpoint
var cargo: Array[CargoItem] = []
var nodes: Array[Vector2] = []
var active: bool = false

# Derived, recomputed on structural recalculation (SPEC §22, §34).
var distance: float
var transport_cost: float
var net_trade_value: float
