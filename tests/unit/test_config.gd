extends GutTest

## Config schema + qualitative-ordering test (SPEC §12, §13, §14, §16, §19,
## §23, §50). Hand-declared expectations, independent of the config values,
## so drift is caught rather than silently reflected back.

const ALL_RESOURCES: Array[SimEnums.ResourceType] = [
	SimEnums.ResourceType.FOOD,
	SimEnums.ResourceType.WATER,
	SimEnums.ResourceType.WOOD,
	SimEnums.ResourceType.METAL,
	SimEnums.ResourceType.STONE,
	SimEnums.ResourceType.WINE,
	SimEnums.ResourceType.LUXURY_GOODS,
]

const ALL_ECHELONS: Array[SimEnums.Echelon] = [
	SimEnums.Echelon.HAMLET,
	SimEnums.Echelon.VILLAGE,
	SimEnums.Echelon.TOWN,
	SimEnums.Echelon.WALLED_CITY,
	SimEnums.Echelon.CAPITAL_TIER,
]


# ---------------------------------------------------------------------------
# (A) SPEC-GIVEN values — exact, law (SPEC §14, §19, §50).
# ---------------------------------------------------------------------------

func test_workforce_matches_spec_exactly() -> void:
	assert_eq(EchelonConfig.workforce(SimEnums.Echelon.HAMLET), 100.0, "Hamlet workforce")
	assert_eq(EchelonConfig.workforce(SimEnums.Echelon.VILLAGE), 500.0, "Village workforce")
	assert_eq(EchelonConfig.workforce(SimEnums.Echelon.TOWN), 2000.0, "Town workforce")
	assert_eq(EchelonConfig.workforce(SimEnums.Echelon.WALLED_CITY), 10000.0, "Walled City workforce")
	assert_eq(EchelonConfig.workforce(SimEnums.Echelon.CAPITAL_TIER), 25000.0, "Capital workforce")


func test_base_attraction_matches_spec_exactly() -> void:
	assert_eq(EchelonConfig.base_attraction(SimEnums.Echelon.HAMLET), 0.1, "Hamlet base_attraction")
	assert_eq(EchelonConfig.base_attraction(SimEnums.Echelon.VILLAGE), 0.3, "Village base_attraction")
	assert_eq(EchelonConfig.base_attraction(SimEnums.Echelon.TOWN), 0.6, "Town base_attraction")
	assert_eq(EchelonConfig.base_attraction(SimEnums.Echelon.WALLED_CITY), 1.0, "Walled City base_attraction")
	assert_eq(EchelonConfig.base_attraction(SimEnums.Echelon.CAPITAL_TIER), 1.5, "Capital base_attraction")


func test_external_price_factors_match_spec_exactly() -> void:
	assert_eq(Tunables.EXTERNAL_EXPORT_PRICE_FACTOR, 0.75, "external_export_price_factor")
	assert_eq(Tunables.EXTERNAL_IMPORT_PRICE_FACTOR, 1.25, "external_import_price_factor")


func test_default_simulation_grid_matches_spec_exactly() -> void:
	assert_eq(Tunables.DEFAULT_SIMULATION_GRID, Vector2i(256, 128), "default simulation grid")


# ---------------------------------------------------------------------------
# Completeness — no missing keys.
# ---------------------------------------------------------------------------

func test_every_resource_has_base_price_and_transport_burden() -> void:
	for resource: SimEnums.ResourceType in ALL_RESOURCES:
		assert_true(
			ResourceConfig.BASE_PRICE.has(resource),
			"missing base_price for resource %s" % resource
		)
		assert_true(
			ResourceConfig.TRANSPORT_BURDEN.has(resource),
			"missing transport_burden for resource %s" % resource
		)
		assert_typeof(ResourceConfig.base_price(resource), TYPE_FLOAT, "base_price(%s)" % resource)
		assert_typeof(ResourceConfig.transport_burden(resource), TYPE_FLOAT, "transport_burden(%s)" % resource)


func test_every_echelon_has_workforce_attraction_capacity() -> void:
	for echelon: SimEnums.Echelon in ALL_ECHELONS:
		assert_true(EchelonConfig.WORKFORCE.has(echelon), "missing workforce for echelon %s" % echelon)
		assert_true(EchelonConfig.BASE_ATTRACTION.has(echelon), "missing base_attraction for echelon %s" % echelon)
		assert_true(EchelonConfig.BASE_CAPACITY.has(echelon), "missing base_capacity for echelon %s" % echelon)
		assert_typeof(EchelonConfig.workforce(echelon), TYPE_FLOAT, "workforce(%s)" % echelon)
		assert_typeof(EchelonConfig.base_attraction(echelon), TYPE_FLOAT, "base_attraction(%s)" % echelon)
		assert_typeof(EchelonConfig.base_capacity(echelon), TYPE_FLOAT, "base_capacity(%s)" % echelon)


func test_every_resource_has_productivity_constant() -> void:
	for resource: SimEnums.ResourceType in ALL_RESOURCES:
		assert_true(
			Tunables.PRODUCTIVITY_CONSTANT.has(resource),
			"missing productivity_constant for resource %s" % resource
		)
		assert_typeof(Tunables.productivity_constant(resource), TYPE_FLOAT, "productivity_constant(%s)" % resource)


func test_every_echelon_has_a_nonempty_mandatory_set() -> void:
	for echelon: SimEnums.Echelon in ALL_ECHELONS:
		assert_true(
			EchelonConfig.MANDATORY_RESOURCES.has(echelon),
			"missing mandatory_resources for echelon %s" % echelon
		)
		var mandatory: Array[SimEnums.ResourceType] = EchelonConfig.mandatory_resources(echelon)
		assert_true(mandatory.size() > 0, "mandatory_resources(%s) should not be empty" % echelon)


func test_seeded_mandatory_boundary() -> void:
	# Seeded assumption (SPEC §13 leaves the exact boundary open): Hamlet/
	# Village need Food/Water/Wood; Town adds Metal; Walled City/Capital add
	# Stone too. This test pins the CURRENT seed so a future recalibration
	# is a deliberate, visible change here, not a silent drift.
	var basic: Array[SimEnums.ResourceType] = [
		SimEnums.ResourceType.FOOD, SimEnums.ResourceType.WATER, SimEnums.ResourceType.WOOD,
	]
	assert_eq(EchelonConfig.mandatory_resources(SimEnums.Echelon.HAMLET), basic, "Hamlet mandatory set")
	assert_eq(EchelonConfig.mandatory_resources(SimEnums.Echelon.VILLAGE), basic, "Village mandatory set")

	assert_true(
		EchelonConfig.mandatory_resources(SimEnums.Echelon.TOWN).has(SimEnums.ResourceType.METAL),
		"Town should require Metal"
	)
	assert_false(
		EchelonConfig.mandatory_resources(SimEnums.Echelon.TOWN).has(SimEnums.ResourceType.STONE),
		"Town should not yet require Stone under the seeded boundary"
	)
	assert_true(
		EchelonConfig.mandatory_resources(SimEnums.Echelon.WALLED_CITY).has(SimEnums.ResourceType.STONE),
		"Walled City should require Stone"
	)
	assert_true(
		EchelonConfig.mandatory_resources(SimEnums.Echelon.CAPITAL_TIER).has(SimEnums.ResourceType.STONE),
		"Capital-tier should require Stone"
	)


# ---------------------------------------------------------------------------
# Qualitative orderings (SPEC §12) — the guarantee is the ranking, not the
# magnitude. Do not assert the exact (B)/(C) placeholder numbers.
# ---------------------------------------------------------------------------

func test_luxury_is_strictly_the_most_valuable_resource() -> void:
	var luxury_price: float = ResourceConfig.base_price(SimEnums.ResourceType.LUXURY_GOODS)
	for resource: SimEnums.ResourceType in ALL_RESOURCES:
		if resource == SimEnums.ResourceType.LUXURY_GOODS:
			continue
		assert_true(
			luxury_price > ResourceConfig.base_price(resource),
			"Luxury Goods base_price should exceed %s" % resource
		)


func test_water_is_strictly_the_least_valuable_resource() -> void:
	var water_price: float = ResourceConfig.base_price(SimEnums.ResourceType.WATER)
	for resource: SimEnums.ResourceType in ALL_RESOURCES:
		if resource == SimEnums.ResourceType.WATER:
			continue
		assert_true(
			water_price < ResourceConfig.base_price(resource),
			"Water base_price should be less than %s" % resource
		)


func test_water_has_strictly_the_highest_transport_burden() -> void:
	var water_burden: float = ResourceConfig.transport_burden(SimEnums.ResourceType.WATER)
	for resource: SimEnums.ResourceType in ALL_RESOURCES:
		if resource == SimEnums.ResourceType.WATER:
			continue
		assert_true(
			water_burden > ResourceConfig.transport_burden(resource),
			"Water transport_burden should exceed %s" % resource
		)


func test_luxury_has_strictly_the_lowest_transport_burden() -> void:
	var luxury_burden: float = ResourceConfig.transport_burden(SimEnums.ResourceType.LUXURY_GOODS)
	for resource: SimEnums.ResourceType in ALL_RESOURCES:
		if resource == SimEnums.ResourceType.LUXURY_GOODS:
			continue
		assert_true(
			luxury_burden < ResourceConfig.transport_burden(resource),
			"Luxury Goods transport_burden should be less than %s" % resource
		)
