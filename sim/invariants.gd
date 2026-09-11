extends RefCounted
class_name Invariants

## Monetary invariant oracles (SPEC §29 L1/L2/L3, §32 L4, §43). Pure
## functions of already-computed state — they check, they never produce.
## No solver/ledger logic lives here: callers (the future monthly tick,
## SPEC §35 step H) supply settled state and ledger entries; these
## functions only compare. Not yet wired into the tick (task 0.5.11/0.5.12).
##
## Float sums are compared with Tunables.INVARIANT_EPSILON, never bare `==`
## (AGENTS.md §6: no literal tolerance in the check body).
##
## `BOUNDARY` (SPEC §29: "source/destination are a settlement id, or
## BOUNDARY") is duplicated here as a local sentinel constant rather than
## added to Transaction (already merged in task 0.2). When sim/tick/ledger.gd
## (task 0.5.11) is built, centralize this in one place — Transaction or
## SimEnums — so the string isn't defined twice.
const BOUNDARY_ID: String = "BOUNDARY"


## Pass/fail result with a human-readable reason on failure, so an
## invariant violation is diagnosable, not just a boolean.
class InvariantResult extends RefCounted:
	var ok: bool = true
	var reason: String = ""

	static func passed() -> InvariantResult:
		var result: InvariantResult = InvariantResult.new()
		result.ok = true
		result.reason = ""
		return result

	static func failed(reason: String) -> InvariantResult:
		var result: InvariantResult = InvariantResult.new()
		result.ok = false
		result.reason = reason
		return result


## L1 — ledger completeness (SPEC §29 Invariant L1, §43): every wealth
## change traces to exactly one settled ledger entry. Checked here as: for
## every settlement, the sum of its ledger entries (its own gross_value
## outflows/inflows) equals its declared wealth_delta_month exactly — no
## unaccounted wealth movement, no double-counted entry.
##
## `settlements` must be supplied in stable-ID order (SPEC §7); this
## function does not sort — sorting is the caller's responsibility.
static func check_l1_ledger_completeness(
	settlements: Array[SettlementState],
	ledger_entries: Array[Transaction],
) -> InvariantResult:
	var ledger_delta_by_settlement: Dictionary[String, float] = {}
	for settlement: SettlementState in settlements:
		ledger_delta_by_settlement[settlement.id] = 0.0

	for entry: Transaction in ledger_entries:
		if entry.source != BOUNDARY_ID and ledger_delta_by_settlement.has(entry.source):
			ledger_delta_by_settlement[entry.source] -= entry.gross_value
		if entry.destination != BOUNDARY_ID and ledger_delta_by_settlement.has(entry.destination):
			ledger_delta_by_settlement[entry.destination] += entry.gross_value

	for settlement: SettlementState in settlements:
		var ledger_delta: float = ledger_delta_by_settlement[settlement.id]
		if not is_equal_approx_with_epsilon(ledger_delta, settlement.wealth_delta_month):
			return InvariantResult.failed(
				"L1: settlement '%s' wealth_delta_month is %s but its ledger entries sum to %s" % [
					settlement.id, settlement.wealth_delta_month, ledger_delta,
				]
			)

	return InvariantResult.passed()


## L2 — conservation by construction (SPEC §29 Invariant L2, §43):
##   Σ domestic_goods_revenue  = Σ domestic_goods_import_cost
##   Σ domestic_service_income = Σ domestic_service_spending
##   Σ wealth_delta            = kingdom_money_delta
##                             = ext_export_rev − ext_import_cost
##                               + foreign_visitor_income − transport_cost_paid
##
## `kingdom_money_delta` is a derived ledger-level output (SPEC §29 step
## DERIVE) with no home yet in WorldState/SettlementState — it is supplied
## by the caller, not computed here.
static func check_l2_conservation(
	settlements: Array[SettlementState],
	kingdom_money_delta: float,
) -> InvariantResult:
	var total_goods_revenue: float = 0.0
	var total_goods_import_cost: float = 0.0
	var total_service_income: float = 0.0
	var total_service_spending: float = 0.0
	var total_wealth_delta: float = 0.0
	var total_external_export_revenue: float = 0.0
	var total_external_import_cost: float = 0.0
	var total_foreign_visitor_income: float = 0.0
	var total_transport_cost_paid: float = 0.0

	for settlement: SettlementState in settlements:
		total_goods_revenue += settlement.domestic_goods_revenue
		total_goods_import_cost += settlement.domestic_goods_import_cost
		total_service_income += settlement.domestic_service_income
		total_service_spending += settlement.domestic_service_spending
		total_wealth_delta += settlement.wealth_delta_month
		total_external_export_revenue += settlement.external_export_revenue
		total_external_import_cost += settlement.external_import_cost
		total_foreign_visitor_income += settlement.foreign_visitor_income
		total_transport_cost_paid += settlement.transport_cost_paid

	if not is_equal_approx_with_epsilon(total_goods_revenue, total_goods_import_cost):
		return InvariantResult.failed(
			"L2: Σ domestic_goods_revenue (%s) != Σ domestic_goods_import_cost (%s)" % [
				total_goods_revenue, total_goods_import_cost,
			]
		)

	if not is_equal_approx_with_epsilon(total_service_income, total_service_spending):
		return InvariantResult.failed(
			"L2: Σ domestic_service_income (%s) != Σ domestic_service_spending (%s)" % [
				total_service_income, total_service_spending,
			]
		)

	if not is_equal_approx_with_epsilon(total_wealth_delta, kingdom_money_delta):
		return InvariantResult.failed(
			"L2: Σ settlement wealth_delta (%s) != kingdom_money_delta (%s)" % [
				total_wealth_delta, kingdom_money_delta,
			]
		)

	var boundary_channels_sum: float = (
		total_external_export_revenue
		- total_external_import_cost
		+ total_foreign_visitor_income
		- total_transport_cost_paid
	)
	if not is_equal_approx_with_epsilon(kingdom_money_delta, boundary_channels_sum):
		return InvariantResult.failed(
			"L2: kingdom_money_delta (%s) != boundary channels sum (%s)" % [
				kingdom_money_delta, boundary_channels_sum,
			]
		)

	return InvariantResult.passed()


## L3 — structural non-negativity (SPEC §29 Invariant L3, §43): a
## settlement's wealth_end >= 0 and every stockpile in [0, capacity], and
## this must hold WITHOUT a repairing clamp firing. `clamp_fired` is a
## caller-supplied flag distinguishing "held naturally" from "held because
## clamped" — nothing sets it yet (that is the settle step's job, task
## 0.5.11), but the oracle is shaped to consume it now.
##
## Checks one settlement at a time; the kingdom-wide invariant is "this
## holds for every settlement," which the caller composes by calling this
## once per settlement.
static func check_l3_non_negativity(
	settlement: SettlementState,
	stockpile_capacities: Dictionary[SimEnums.ResourceType, float],
	clamp_fired: bool,
) -> InvariantResult:
	if clamp_fired:
		return InvariantResult.failed(
			"L3: settlement '%s' held non-negativity only because a repairing clamp fired" % settlement.id
		)

	if settlement.wealth < -Tunables.INVARIANT_EPSILON:
		return InvariantResult.failed(
			"L3: settlement '%s' wealth is %s (< 0)" % [settlement.id, settlement.wealth]
		)

	for resource: SimEnums.ResourceType in settlement.stockpiles.keys():
		var quantity: float = settlement.stockpiles[resource]
		var capacity: float = stockpile_capacities.get(resource, 0.0)
		if quantity < -Tunables.INVARIANT_EPSILON:
			return InvariantResult.failed(
				"L3: settlement '%s' stockpile[%s] is %s (< 0)" % [settlement.id, resource, quantity]
			)
		if quantity > capacity + Tunables.INVARIANT_EPSILON:
			return InvariantResult.failed(
				"L3: settlement '%s' stockpile[%s] is %s (> capacity %s)" % [
					settlement.id, resource, quantity, capacity,
				]
			)

	return InvariantResult.passed()


## L4 — the foreign faucet has a governor (SPEC §32 Invariant L4, §43):
## foreign_visitor_income is bounded by remaining service capacity, exactly
## like domestic service income. No uncapped mint.
static func check_l4_foreign_faucet_governor(
	foreign_visitor_income: float,
	remaining_service_capacity: float,
) -> InvariantResult:
	if foreign_visitor_income > remaining_service_capacity + Tunables.INVARIANT_EPSILON:
		return InvariantResult.failed(
			"L4: foreign_visitor_income (%s) exceeds remaining_service_capacity (%s)" % [
				foreign_visitor_income, remaining_service_capacity,
			]
		)

	return InvariantResult.passed()


static func is_equal_approx_with_epsilon(a: float, b: float) -> bool:
	return absf(a - b) <= Tunables.INVARIANT_EPSILON
