extends GutTest

## Schema test for sim/state canonical vocabulary (SPEC §22, §25, §29, §38,
## §39, §40; AGENTS.md §7). Expected fields/types are hand-written here from
## the spec text, independent of the class implementations, so a rename or
## mistyping in a class is caught rather than silently reflected back.

const ALL_RESOURCES: Array[SimEnums.ResourceType] = [
	SimEnums.ResourceType.FOOD,
	SimEnums.ResourceType.WATER,
	SimEnums.ResourceType.WOOD,
	SimEnums.ResourceType.METAL,
	SimEnums.ResourceType.STONE,
	SimEnums.ResourceType.WINE,
	SimEnums.ResourceType.LUXURY_GOODS,
]


func _assert_resource_float_dict(dict: Variant, label: String) -> void:
	assert_true(dict is Dictionary, "%s should be a Dictionary" % label)
	for resource: SimEnums.ResourceType in ALL_RESOURCES:
		assert_true(dict.has(resource), "%s missing entry for resource %s" % [label, resource])
		assert_typeof(dict.get(resource), TYPE_FLOAT, "%s[%s]" % [label, resource])


# ---------------------------------------------------------------------------
# SettlementState — SPEC §38
# ---------------------------------------------------------------------------

func test_settlement_state_schema() -> void:
	var s: SettlementState = SettlementState.new()

	assert_typeof(s.id, TYPE_STRING, "SettlementState.id")
	assert_typeof(s.name, TYPE_STRING, "SettlementState.name")
	assert_typeof(s.map_position, TYPE_VECTOR2, "SettlementState.map_position")

	assert_true(s.echelon is int, "SettlementState.echelon should be an Echelon enum value")
	assert_typeof(s.is_kingdom_capital, TYPE_BOOL, "SettlementState.is_kingdom_capital")

	assert_typeof(s.nominal_workforce, TYPE_FLOAT, "SettlementState.nominal_workforce")
	assert_typeof(s.productive_workforce, TYPE_FLOAT, "SettlementState.productive_workforce")

	assert_typeof(s.wealth, TYPE_FLOAT, "SettlementState.wealth")
	assert_typeof(s.wealth_delta_month, TYPE_FLOAT, "SettlementState.wealth_delta_month")

	_assert_resource_float_dict(s.stockpiles, "SettlementState.stockpiles")
	_assert_resource_float_dict(s.production_rates, "SettlementState.production_rates")
	_assert_resource_float_dict(s.consumption_rates, "SettlementState.consumption_rates")
	_assert_resource_float_dict(s.imports, "SettlementState.imports")
	_assert_resource_float_dict(s.exports, "SettlementState.exports")

	assert_typeof(s.domestic_goods_revenue, TYPE_FLOAT, "SettlementState.domestic_goods_revenue")
	assert_typeof(s.domestic_goods_import_cost, TYPE_FLOAT, "SettlementState.domestic_goods_import_cost")
	assert_typeof(s.domestic_service_income, TYPE_FLOAT, "SettlementState.domestic_service_income")
	assert_typeof(s.domestic_service_spending, TYPE_FLOAT, "SettlementState.domestic_service_spending")
	assert_typeof(s.external_export_revenue, TYPE_FLOAT, "SettlementState.external_export_revenue")
	assert_typeof(s.external_import_cost, TYPE_FLOAT, "SettlementState.external_import_cost")
	assert_typeof(s.foreign_visitor_income, TYPE_FLOAT, "SettlementState.foreign_visitor_income")
	assert_typeof(s.transport_cost_paid, TYPE_FLOAT, "SettlementState.transport_cost_paid")

	assert_true(s.mandatory_status is Dictionary, "SettlementState.mandatory_status should be a Dictionary")
	for resource: SimEnums.ResourceType in ALL_RESOURCES:
		assert_true(s.mandatory_status.has(resource), "mandatory_status missing entry for resource %s" % resource)
		var entry: Variant = s.mandatory_status.get(resource)
		assert_true(entry is SettlementState.MandatoryStatus, "mandatory_status[%s] should be a MandatoryStatus" % resource)
		assert_typeof(entry.covered, TYPE_BOOL, "MandatoryStatus.covered")
		assert_typeof(entry.months_to_zero, TYPE_FLOAT, "MandatoryStatus.months_to_zero")

	_assert_resource_float_dict(s.wants_status, "SettlementState.wants_status")

	assert_typeof(s.export_capacity, TYPE_FLOAT, "SettlementState.export_capacity")
	assert_typeof(s.export_capacity_used, TYPE_FLOAT, "SettlementState.export_capacity_used")
	assert_typeof(s.service_capacity, TYPE_FLOAT, "SettlementState.service_capacity")
	assert_typeof(s.service_utilization, TYPE_FLOAT, "SettlementState.service_utilization")
	assert_typeof(s.attractiveness, TYPE_FLOAT, "SettlementState.attractiveness")
	assert_typeof(s.traffic, TYPE_FLOAT, "SettlementState.traffic")
	assert_typeof(s.disposable_income, TYPE_FLOAT, "SettlementState.disposable_income")
	assert_typeof(s.discretionary_budget, TYPE_FLOAT, "SettlementState.discretionary_budget")
	assert_typeof(s.catchment_radius, TYPE_FLOAT, "SettlementState.catchment_radius")
	assert_typeof(s.projected_treasury_zero, TYPE_FLOAT, "SettlementState.projected_treasury_zero")


# ---------------------------------------------------------------------------
# WorldState — SPEC §39
# ---------------------------------------------------------------------------

func test_world_state_schema() -> void:
	var w: WorldState = WorldState.new()

	assert_typeof(w.world_id, TYPE_STRING, "WorldState.world_id")
	assert_typeof(w.world_name, TYPE_STRING, "WorldState.world_name")
	assert_typeof(w.simulation_year, TYPE_INT, "WorldState.simulation_year")
	assert_typeof(w.simulation_month, TYPE_INT, "WorldState.simulation_month")
	assert_typeof(w.paused, TYPE_BOOL, "WorldState.paused")
	assert_typeof(w.speed, TYPE_FLOAT, "WorldState.speed")
	assert_typeof(w.map_asset, TYPE_STRING, "WorldState.map_asset")
	assert_typeof(w.simulation_grid, TYPE_VECTOR2I, "WorldState.simulation_grid")

	assert_true(w.settlements is Array, "WorldState.settlements should be an Array")
	assert_true(w.trade_routes is Array, "WorldState.trade_routes should be an Array")
	assert_true(w.external_economy is Array, "WorldState.external_economy should be an Array")
	assert_true(w.recommendations is Array, "WorldState.recommendations should be an Array")

	assert_typeof(w.economic_version, TYPE_INT, "WorldState.economic_version")
	assert_typeof(w.random_seed, TYPE_INT, "WorldState.random_seed")


# ---------------------------------------------------------------------------
# TradeRoute + TradeEndpoint — SPEC §22, §40
# ---------------------------------------------------------------------------

func test_trade_route_and_endpoint_schema() -> void:
	var r: TradeRoute = TradeRoute.new()

	assert_typeof(r.id, TYPE_STRING, "TradeRoute.id")

	r.source_endpoint = TradeRoute.TradeEndpoint.new()
	r.destination_endpoint = TradeRoute.TradeEndpoint.new()
	assert_true(r.source_endpoint is TradeRoute.TradeEndpoint, "TradeRoute.source_endpoint")
	assert_true(r.destination_endpoint is TradeRoute.TradeEndpoint, "TradeRoute.destination_endpoint")
	assert_true(r.source_endpoint.type is int, "TradeEndpoint.type should be an EndpointType enum value")
	assert_typeof(r.source_endpoint.id, TYPE_STRING, "TradeEndpoint.id")

	assert_true(r.cargo is Array, "TradeRoute.cargo should be an Array")
	var item: TradeRoute.CargoItem = TradeRoute.CargoItem.new()
	item.resource = SimEnums.ResourceType.WOOD
	item.quantity_per_month = 12.0
	r.cargo.append(item)
	assert_true(r.cargo[0] is TradeRoute.CargoItem, "TradeRoute.cargo[] entries should be CargoItem")
	assert_true(r.cargo[0].resource is int, "CargoItem.resource should be a ResourceType enum value")
	assert_typeof(r.cargo[0].quantity_per_month, TYPE_FLOAT, "CargoItem.quantity_per_month")

	assert_true(r.nodes is Array, "TradeRoute.nodes should be an Array (presentation-only)")
	assert_typeof(r.active, TYPE_BOOL, "TradeRoute.active")

	assert_typeof(r.distance, TYPE_FLOAT, "TradeRoute.distance")
	assert_typeof(r.transport_cost, TYPE_FLOAT, "TradeRoute.transport_cost")
	assert_typeof(r.net_trade_value, TYPE_FLOAT, "TradeRoute.net_trade_value")


# ---------------------------------------------------------------------------
# ExternalMarket / external_economy — SPEC §25
# ---------------------------------------------------------------------------

func test_external_market_schema() -> void:
	var m: ExternalMarket = ExternalMarket.new()

	assert_typeof(m.id, TYPE_STRING, "ExternalMarket.id")
	assert_typeof(m.map_position, TYPE_VECTOR2, "ExternalMarket.map_position")
	assert_true(m.price_list is Dictionary, "ExternalMarket.price_list should be a Dictionary")


# ---------------------------------------------------------------------------
# ResourceFields — SPEC §10, §11
# ---------------------------------------------------------------------------

func test_resource_fields_schema() -> void:
	var f: ResourceFields = ResourceFields.new()

	assert_typeof(f.grid_width, TYPE_INT, "ResourceFields.grid_width")
	assert_typeof(f.grid_height, TYPE_INT, "ResourceFields.grid_height")

	assert_typeof(f.moisture, TYPE_PACKED_FLOAT32_ARRAY, "ResourceFields.moisture")
	assert_typeof(f.fertility, TYPE_PACKED_FLOAT32_ARRAY, "ResourceFields.fertility")
	assert_typeof(f.forestability, TYPE_PACKED_FLOAT32_ARRAY, "ResourceFields.forestability")
	assert_typeof(f.rockiness, TYPE_PACKED_FLOAT32_ARRAY, "ResourceFields.rockiness")
	assert_typeof(f.mineralization, TYPE_PACKED_FLOAT32_ARRAY, "ResourceFields.mineralization")
	assert_typeof(f.dryness, TYPE_PACKED_FLOAT32_ARRAY, "ResourceFields.dryness")
	assert_typeof(f.elevation, TYPE_PACKED_FLOAT32_ARRAY, "ResourceFields.elevation")

	assert_true(f.potential is Dictionary, "ResourceFields.potential should be a Dictionary")
	for resource: SimEnums.ResourceType in ALL_RESOURCES:
		assert_true(f.potential.has(resource), "ResourceFields.potential missing entry for resource %s" % resource)
		assert_typeof(f.potential.get(resource), TYPE_PACKED_FLOAT32_ARRAY, "ResourceFields.potential[%s]" % resource)


# ---------------------------------------------------------------------------
# Transaction — SPEC §29
# ---------------------------------------------------------------------------

func test_transaction_schema() -> void:
	var t: Transaction = Transaction.new()

	assert_true(t.type is int, "Transaction.type should be a TransactionType enum value")
	assert_typeof(t.source, TYPE_STRING, "Transaction.source")
	assert_typeof(t.destination, TYPE_STRING, "Transaction.destination")
	assert_eq(t.resource, null, "Transaction.resource should default to null (SPEC §29: null for service/transport)")

	t.resource = SimEnums.ResourceType.FOOD
	assert_true(t.resource is int, "Transaction.resource should hold a ResourceType enum value when set")

	assert_typeof(t.quantity, TYPE_FLOAT, "Transaction.quantity")
	assert_typeof(t.gross_value, TYPE_FLOAT, "Transaction.gross_value")
	assert_typeof(t.boundary_flag, TYPE_BOOL, "Transaction.boundary_flag")


# ---------------------------------------------------------------------------
# Enum vocabulary — SPEC §12, §13, §22, §29
# ---------------------------------------------------------------------------

func test_echelon_enum_has_five_tiers() -> void:
	assert_eq(SimEnums.Echelon.size(), 5, "Echelon should have exactly 5 tiers")
	assert_true("HAMLET" in SimEnums.Echelon)
	assert_true("VILLAGE" in SimEnums.Echelon)
	assert_true("TOWN" in SimEnums.Echelon)
	assert_true("WALLED_CITY" in SimEnums.Echelon)
	assert_true("CAPITAL_TIER" in SimEnums.Echelon)


func test_resource_type_enum_has_seven_resources() -> void:
	assert_eq(SimEnums.ResourceType.size(), 7, "ResourceType should have exactly 7 resources")
	assert_true("FOOD" in SimEnums.ResourceType)
	assert_true("WATER" in SimEnums.ResourceType)
	assert_true("WOOD" in SimEnums.ResourceType)
	assert_true("METAL" in SimEnums.ResourceType)
	assert_true("STONE" in SimEnums.ResourceType)
	assert_true("WINE" in SimEnums.ResourceType)
	assert_true("LUXURY_GOODS" in SimEnums.ResourceType)


func test_transaction_type_enum_has_five_types() -> void:
	assert_eq(SimEnums.TransactionType.size(), 5, "TransactionType should have exactly 5 types")
	assert_true("GOODS_DOMESTIC" in SimEnums.TransactionType)
	assert_true("GOODS_EXTERNAL" in SimEnums.TransactionType)
	assert_true("SERVICE_DOMESTIC" in SimEnums.TransactionType)
	assert_true("SERVICE_FOREIGN" in SimEnums.TransactionType)
	assert_true("TRANSPORT" in SimEnums.TransactionType)


func test_endpoint_type_enum_has_two_types() -> void:
	assert_eq(SimEnums.EndpointType.size(), 2, "EndpointType should have exactly 2 types")
	assert_true("SETTLEMENT" in SimEnums.EndpointType)
	assert_true("EXTERNAL_MARKET" in SimEnums.EndpointType)
