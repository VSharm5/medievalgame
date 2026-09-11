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


func test_l1_fails_on_entry_referencing_unknown_settlement() -> void:
	var seller: SettlementState = _make_settlement("SELLER")
	seller.wealth_delta_month = 5.0

	# "GHOST" is not a known settlement and not BOUNDARY -- this must be a
	# violation, not a silently dropped entry.
	var entries: Array[Transaction] = [_make_transaction("GHOST", "SELLER", 5.0)]

	var result: Invariants.InvariantResult = Invariants.check_l1_ledger_completeness(
		[seller], entries
	)
	assert_false(result.ok, "L1 should fail when an entry references an unknown settlement id")
	assert_string_contains(result.reason, "GHOST")


func test_l1_result_is_order_independent() -> void:
	# Magnitudes are chosen so that summation order actually changes the
	# floating-point result (catastrophic cancellation), not just a
	# reordering that happens to sum identically either way: adding 1.0 to
	# a running total of 1e20 is completely absorbed (no representable
	# change at that magnitude), so "big, tiny, big-negative" nets to 0.0
	# while "big, big-negative, tiny" nets to 1.0 -- a real, >>epsilon
	# difference that only a canonical (sorted) processing order avoids.
	var s: SettlementState = _make_settlement("S")
	s.wealth_delta_month = 0.0  # the canonical, sorted-order answer

	var entry_big_in: Transaction = _make_transaction(Invariants.BOUNDARY_ID, "S", 1e20)
	var entry_tiny_in: Transaction = _make_transaction(Invariants.BOUNDARY_ID, "S", 1.0)
	var entry_big_out: Transaction = _make_transaction("S", Invariants.BOUNDARY_ID, 1e20)

	var order_a: Array[Transaction] = [entry_big_in, entry_tiny_in, entry_big_out]
	var order_b: Array[Transaction] = [entry_big_in, entry_big_out, entry_tiny_in]

	var result_a: Invariants.InvariantResult = Invariants.check_l1_ledger_completeness([s], order_a)
	var result_b: Invariants.InvariantResult = Invariants.check_l1_ledger_completeness([s], order_b)

	assert_true(result_a.ok, "L1 should pass under canonical ordering: %s" % result_a.reason)
	assert_eq(result_a.ok, result_b.ok, "L1 result.ok should not depend on input order")
	assert_eq(result_a.reason, result_b.reason, "L1 result.reason should not depend on input order")


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


func test_l2_result_is_order_independent() -> void:
	# Same catastrophic-cancellation trick as the L1 order test: magnitudes
	# chosen so summation order changes the float result by way more than
	# epsilon, not a reordering that happens to sum identically either way.
	# domestic_goods_import_cost is 0.0 for all three (order-insensitive),
	# so the check's pass/fail hinges entirely on how domestic_goods_revenue
	# sums -- 0.0 (absorbed) if id-sorted "A, B, C", 1.0 if summed as
	# "A, C, B" without sorting.
	var settlement_a: SettlementState = _make_settlement("A")
	settlement_a.domestic_goods_revenue = 1e20

	var settlement_b: SettlementState = _make_settlement("B")
	settlement_b.domestic_goods_revenue = 1.0

	var settlement_c: SettlementState = _make_settlement("C")
	settlement_c.domestic_goods_revenue = -1e20

	var order_a: Array[SettlementState] = [settlement_a, settlement_b, settlement_c]
	var order_b: Array[SettlementState] = [settlement_a, settlement_c, settlement_b]

	var result_a: Invariants.InvariantResult = Invariants.check_l2_conservation(order_a, 0.0)
	var result_b: Invariants.InvariantResult = Invariants.check_l2_conservation(order_b, 0.0)

	assert_true(result_a.ok, "L2 should pass under canonical (id-sorted) ordering: %s" % result_a.reason)
	assert_eq(result_a.ok, result_b.ok, "L2 result.ok should not depend on input order")
	assert_eq(result_a.reason, result_b.reason, "L2 result.reason should not depend on input order")


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
