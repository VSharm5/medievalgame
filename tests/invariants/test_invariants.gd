extends GutTest

## Tests for the invariant oracles themselves (sim/invariants.gd), against
## hand-built fixtures — there is no economy yet, so these prove the
## checks catch violations and pass clean state, not that a real solver
## behaves. SPEC §29 (L1/L2/L3), §32 (L4), §43.


func _make_settlement(id: String) -> SettlementState:
	var s: SettlementState = SettlementState.new()
	s.id = id
	return s


func _make_transaction(source: String, destination: String, gross_value: float) -> Transaction:
	var t: Transaction = Transaction.new()
	t.type = SimEnums.TransactionType.GOODS_DOMESTIC
	t.source = source
	t.destination = destination
	t.quantity = 1.0
	t.gross_value = gross_value
	t.boundary_flag = (source == Invariants.BOUNDARY_ID or destination == Invariants.BOUNDARY_ID)
	return t


# ---------------------------------------------------------------------------
# L1 — ledger completeness
# ---------------------------------------------------------------------------

func test_l1_passes_when_wealth_delta_matches_ledger_entries() -> void:
	var seller: SettlementState = _make_settlement("SELLER")
	var buyer: SettlementState = _make_settlement("BUYER")
	seller.wealth_delta_month = 10.0
	buyer.wealth_delta_month = -10.0

	var entries: Array[Transaction] = [_make_transaction("BUYER", "SELLER", 10.0)]

	var result: Invariants.InvariantResult = Invariants.check_l1_ledger_completeness(
		[seller, buyer], entries
	)
	assert_true(result.ok, "L1 should pass: %s" % result.reason)


func test_l1_fails_when_wealth_delta_is_unaccounted() -> void:
	var seller: SettlementState = _make_settlement("SELLER")
	var buyer: SettlementState = _make_settlement("BUYER")
	seller.wealth_delta_month = 10.0
	buyer.wealth_delta_month = -10.0

	# Ledger only records half the claimed transfer -- seller's declared
	# wealth_delta_month is not traceable to a settled entry.
	var entries: Array[Transaction] = [_make_transaction("BUYER", "SELLER", 5.0)]

	var result: Invariants.InvariantResult = Invariants.check_l1_ledger_completeness(
		[seller, buyer], entries
	)
	assert_false(result.ok, "L1 should fail on unaccounted wealth change")
	assert_string_contains(result.reason, "SELLER")


# ---------------------------------------------------------------------------
# L2 — conservation
# ---------------------------------------------------------------------------

func _balanced_l2_settlements() -> Array[SettlementState]:
	# A sells 100 domestic goods + 20 domestic services to B; A also exports
	# 50 externally and pays 5 transport. B imports 10 externally and draws
	# 3 in foreign visitor income.
	var a: SettlementState = _make_settlement("A")
	a.domestic_goods_revenue = 100.0
	a.domestic_service_income = 20.0
	a.external_export_revenue = 50.0
	a.transport_cost_paid = 5.0
	a.wealth_delta_month = 100.0 + 20.0 + 50.0 - 5.0

	var b: SettlementState = _make_settlement("B")
	b.domestic_goods_import_cost = 100.0
	b.domestic_service_spending = 20.0
	b.external_import_cost = 10.0
	b.foreign_visitor_income = 3.0
	b.wealth_delta_month = -100.0 - 20.0 - 10.0 + 3.0

	return [a, b]


func test_l2_passes_on_a_balanced_fixture() -> void:
	var settlements: Array[SettlementState] = _balanced_l2_settlements()
	var kingdom_money_delta: float = (
		50.0 - 10.0 + 3.0 - 5.0  # ext_export - ext_import + foreign_visitor - transport
	)

	var result: Invariants.InvariantResult = Invariants.check_l2_conservation(
		settlements, kingdom_money_delta
	)
	assert_true(result.ok, "L2 should pass on a balanced fixture: %s" % result.reason)


func test_l2_fails_on_a_one_unit_goods_imbalance() -> void:
	var settlements: Array[SettlementState] = _balanced_l2_settlements()
	# Deliberate 1-unit imbalance: revenue no longer equals import cost.
	settlements[0].domestic_goods_revenue += 1.0

	var kingdom_money_delta: float = 50.0 - 10.0 + 3.0 - 5.0

	var result: Invariants.InvariantResult = Invariants.check_l2_conservation(
		settlements, kingdom_money_delta
	)
	assert_false(result.ok, "L2 should fail on a 1-unit goods imbalance")
	assert_string_contains(result.reason, "domestic_goods_revenue")


func test_l2_passes_within_epsilon_tolerance() -> void:
	var settlements: Array[SettlementState] = _balanced_l2_settlements()
	# Sub-epsilon float noise (Tunables.INVARIANT_EPSILON = 1e-6).
	settlements[0].domestic_goods_revenue += 1e-9

	var kingdom_money_delta: float = 50.0 - 10.0 + 3.0 - 5.0

	var result: Invariants.InvariantResult = Invariants.check_l2_conservation(
		settlements, kingdom_money_delta
	)
	assert_true(result.ok, "L2 should tolerate sub-epsilon float noise: %s" % result.reason)


func test_l2_fails_outside_epsilon_tolerance() -> void:
	var settlements: Array[SettlementState] = _balanced_l2_settlements()
	# Well above epsilon (1e-6).
	settlements[0].domestic_goods_revenue += 1e-3

	var kingdom_money_delta: float = 50.0 - 10.0 + 3.0 - 5.0

	var result: Invariants.InvariantResult = Invariants.check_l2_conservation(
		settlements, kingdom_money_delta
	)
	assert_false(result.ok, "L2 should fail on an out-of-epsilon mismatch")


# ---------------------------------------------------------------------------
# L3 — structural non-negativity
# ---------------------------------------------------------------------------

func _default_capacities() -> Dictionary[SimEnums.ResourceType, float]:
	return {
		SimEnums.ResourceType.FOOD: 100.0,
		SimEnums.ResourceType.WATER: 100.0,
		SimEnums.ResourceType.WOOD: 100.0,
		SimEnums.ResourceType.METAL: 100.0,
		SimEnums.ResourceType.STONE: 100.0,
		SimEnums.ResourceType.WINE: 100.0,
		SimEnums.ResourceType.LUXURY_GOODS: 100.0,
	}


func test_l3_passes_on_a_clean_fixture() -> void:
	var s: SettlementState = _make_settlement("S")
	s.wealth = 50.0
	s.stockpiles[SimEnums.ResourceType.FOOD] = 10.0

	var result: Invariants.InvariantResult = Invariants.check_l3_non_negativity(
		s, _default_capacities(), false
	)
	assert_true(result.ok, "L3 should pass on a clean fixture: %s" % result.reason)


func test_l3_fails_on_negative_wealth() -> void:
	var s: SettlementState = _make_settlement("S")
	s.wealth = -1.0

	var result: Invariants.InvariantResult = Invariants.check_l3_non_negativity(
		s, _default_capacities(), false
	)
	assert_false(result.ok, "L3 should fail on negative wealth")


func test_l3_fails_when_a_repairing_clamp_fired() -> void:
	var s: SettlementState = _make_settlement("S")
	# Otherwise perfectly clean -- non-negative wealth, in-range stockpiles.
	s.wealth = 50.0
	s.stockpiles[SimEnums.ResourceType.FOOD] = 10.0

	var result: Invariants.InvariantResult = Invariants.check_l3_non_negativity(
		s, _default_capacities(), true
	)
	assert_false(result.ok, "L3 should fail when clamp_fired is true, even with in-range values")
	assert_string_contains(result.reason, "clamp")


func test_l3_fails_on_stockpile_over_capacity() -> void:
	var s: SettlementState = _make_settlement("S")
	s.wealth = 50.0
	s.stockpiles[SimEnums.ResourceType.FOOD] = 150.0

	var result: Invariants.InvariantResult = Invariants.check_l3_non_negativity(
		s, _default_capacities(), false
	)
	assert_false(result.ok, "L3 should fail when a stockpile exceeds capacity")


# ---------------------------------------------------------------------------
# L4 — foreign faucet governor
# ---------------------------------------------------------------------------

func test_l4_passes_when_foreign_income_is_within_capacity() -> void:
	var result: Invariants.InvariantResult = Invariants.check_l4_foreign_faucet_governor(30.0, 50.0)
	assert_true(result.ok, "L4 should pass when income is within remaining capacity: %s" % result.reason)


func test_l4_fails_when_foreign_income_exceeds_capacity() -> void:
	var result: Invariants.InvariantResult = Invariants.check_l4_foreign_faucet_governor(60.0, 50.0)
	assert_false(result.ok, "L4 should fail when income exceeds remaining capacity")
