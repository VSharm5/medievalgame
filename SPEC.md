# THE MEDIEVAL GAME — V1 SPECIFICATION

**Deterministic medieval logistics & economic sandbox • Godot 4.x desktop build**

**Status:** Authoritative V1 law. This document supersedes all prior drafts and conversation notes. Where any other artifact disagrees with this document, this document wins.

**How to read this document:** Numbered sections are normative. Text in *Rationale* notes is explanatory, not binding. Formulas are the contract; constants shown are starting tuning values and live in central configuration, never in code paths.

---

# PART I — VISION & SCOPE

## 1. Product Definition

The Medieval Game is a deterministic sandbox in which a kingdom's economy emerges from geography, settlement specialization, distance, logistics, trade, and monetary circulation.

The player builds the physical and political structure of a kingdom — placing settlements, assigning echelons, authoring resource geography, and approving trade connections — and observes the consequences. The player does not micromanage economic actors.

**Central thesis:** *Do not simulate medieval life. Simulate the logistical consequences of medieval settlement.*

**Economic thesis:** *Geography creates productive potential; distance determines what that potential is worth elsewhere.*

## 2. Emergent Goals

The rules must produce these outcomes without scripting them:

- Bulk goods stay local; light, valuable goods travel far.
- A resource-rich settlement can be economically irrelevant if it is too far from demand.
- Larger, specialized settlements become import-dependent and therefore fragile.
- Settlements grow wealthy by capturing discretionary spending, not only by producing.
- The kingdom's total money supply self-stabilizes through an open external boundary.
- Networks matter more than isolated local abundance.
- Failure propagates through the economy along visible causal chains.

**Player experience:** *Build a kingdom. Understand why it works. Understand why it fails. Watch the consequences unfold.*

## 3. Success Criteria

V1 succeeds when the player can, in a polished desktop application: create or load a world; author resource geography; place settlements and assign echelons; establish and reject trade routes (domestic and external); observe production, stockpiles, wealth, capacity limits, attractiveness, and service circulation over time; designate one kingdom capital; upgrade settlements and observe specialization consequences; trade with an abstract external economy; watch kingdom-wide money enter and leave through the boundary; fast-forward deterministically; save/load; and inspect *why* any settlement is succeeding or failing.

## 4. Non-Goals

V1 does **not** model: military, warfare, armies, or diplomacy; individual citizens, demographics, births/deaths, or migration; detailed production chains; banking, loans, interest, debt, taxation, or tariffs; individual professions or personal services; terrain-dependent pathfinding; spoilage or perishability; seasons; technology, unlocks, or campaign progression; foreign governments, populations, or civilizations (the external economy is a deliberate abstraction, not a simulated neighbor).

**Consequence of "no debt":** because no settlement may hold negative wealth, affordability is a hard constraint enforced before any transaction settles (§29, §33). There is no borrowing to paper over a shortfall.

---

# PART II — PLATFORM, ARCHITECTURE & DETERMINISM

## 5. Technical Platform

| Component | Decision |
|---|---|
| Engine | Godot 4.x, 2D |
| Language | GDScript |
| Platforms | Windows / macOS / Linux |
| Persistence | JSON world/save packages |
| Simulation | Deterministic, discrete monthly steps |
| Randomness | None in V1; seeded RNG reserved |
| Source control | Git; project runs from a clean checkout |

## 6. High-Level Architecture

```text
Simulation Core (headless, testable without UI)
  ├── WorldState / SettlementState / TradeRoute / ExternalEconomy / ResourceFields
  ├── EconomicSolver        (recalculate_world)
  ├── MonthlyTick           (advance_month, ledger-based)
  ├── TransactionLedger     (the single source of monetary truth)
  └── RecommendationEngine

Presentation (reads state, never writes it)
  ├── MapRenderer / SettlementRenderer / RouteRenderer / ResourceLensRenderer / Camera

UI (issues commands to the controller, never mutates simulation internals)
  └── Menus / TopBar / Toolbar / Inspectors / RecommendationPanel / SimControls / WorldDesigner

Persistence
  └── Save / Load / Versioning
```

The simulation core must be runnable and testable with no renderer attached.

## 7. Determinism (Foundational)

Determinism governs every other rule. Given the same world, the same player decision sequence, and the same number of elapsed months, the resulting state must be **bit-stable**.

- No unseeded randomness. (V1 uses none at all.)
- All aggregation over routes, settlements, resources, and ledger entries iterates in **stable-ID order** before any floating-point accumulation.
- All allocation and scaling decisions (export capacity, affordability, service capacity) resolve by a defined deterministic priority with a stable-ID final tiebreak.
- Fixed simulation steps; no frame-rate dependence; UI animation never touches authoritative state.
- Fast-forward is an *optimization of the same simulation*, not a second code path (§36). It must produce identical state to month-by-month playback.

---

# PART III — WORLD & GEOGRAPHY

## 8. World Package & Semantic Map

The imported map image is a **visual layer only**. The simulation never infers economic properties from pixels.

```text
WorldPackage {
    world_id, world_name
    map_asset               # PNG/WebP, loaded once, reused
    simulation_grid         # e.g. 256×128 for a 2048×1024 image
    resource_fields
    settlements
    trade_routes
    external_economy
    simulation_clock
    config_version
    random_seed             # reserved, unused in V1
}
```

## 9. World Designer

A first-class V1 tool (not a debug utility) that lets a creator import art and author semantic geography.

**Authoring principle:** *The player authors a world; the simulation interprets it.* Brushes paint **influences**, not final resource percentages. A forest brush means "this environment is forest-like," not "this cell is 80% wood." The World Evaluator converts influences + environmental fields + neighbor context into final potential.

Brushes have radius, strength, falloff, hardness, and an erase/reduce operation. Influences overlap and combine. The Designer previews derived resource potential using the *same* lens renderer as the game (§ UI), so the author sees true simulation output.

## 10. Simulation Grid & Environmental Fields

The grid is a computational structure for spatial evaluation, not a set of scene nodes (§ Performance). It is not a pathfinding terrain system; economic distance is defined by coordinates (§20).

Per-cell continuous fields:

| Field | Meaning | Primary effect |
|---|---|---|
| Moisture | Water-supporting environment | Water, wood, food |
| Fertility | Agricultural suitability | Food |
| Forestability | Woodland sustainability | Wood |
| Rockiness | Stone accessibility | Stone |
| Mineralization | Useful metal likelihood | Metal |
| Dryness | Inverse of moisture | Faster water decay; weaker wood/food |
| Elevation | Broad geography | Visual / future use |

Influence falloff may be modified by environment (a river holds a broad moist corridor through forest, a narrow one through desert). Values are tuning parameters.

## 11. Resource Fields

For each cell `c` and resource `r`:

```text
raw_r(c)       = affinity_r(c) × environment_modifier_r(c) × neighbor_modifier_r(c)
potential_r(c) = clamp01(normalize(raw_r(c)))
```

A spatial smoothing pass runs after influence aggregation to produce gradients rather than hard-edged regions. Wine and Luxury Goods may be authored as coarse potential rather than modeled from production chains.

## 12. Resources

```text
Resource { resource_type, base_price, transport_burden }
```

| Resource | Role | Mandatory? | Transport burden | Value |
|---|---|---|---|---|
| Food | Survival | Yes | Medium/High | Low |
| Water | Survival | Yes | Very High | Very Low |
| Wood | Construction/fuel | Yes | High | Low |
| Metal | Advanced requirement | Higher echelons | Medium | Medium |
| Stone | Advanced requirement | Higher echelons | Very High | Low/Medium |
| Wine | Want | No | Medium | Medium |
| Luxury Goods | Want | No | Very Low | Very High |

**Value and transport burden are independent** — this independence is the engine of emergent trade geography. Water is cheap but crippling to move; luxury is precious but light.

---

# PART IV — SETTLEMENTS

## 13. Settlement Model & Echelons

Echelons: **Hamlet → Village → Town → Walled City → Capital-tier.**

Exactly one settlement carries the **Kingdom Capital** flag. Capital-*tier* (size) and Kingdom-*Capital* (political role) are independent properties; multiple capital-tier settlements may exist, but only one is the Kingdom Capital.

Mandatory needs by echelon rise as settlements grow: Hamlets require Food, Water, Wood; higher echelons add Metal and Stone and larger quantities of the basics.

## 14. Workforce

Fixed nominal workforce per echelon; no population dynamics.

```text
available_workforce = nominal_workforce − baseline_workforce_cost(echelon)
```

| Echelon | Nominal workforce |
|---|---|
| Hamlet | 100 |
| Village | 500 |
| Town | 2,000 |
| Walled City | 10,000 |
| Capital-tier | 25,000 |

**Monotonic specialization (design invariant):** higher echelons hold more total labor but spend a larger share on baseline/specialized function, so productive workforce grows *sublinearly* with size. Bigger settlements are therefore more import-dependent, not strictly better.

## 15. Settlement Production

```text
monthly_production[r] =
    productive_workforce × production_share[r] × local_resource_potential[r] × productivity_constant[r]
```

Local potential is sampled as the catchment-weighted average of surrounding cells (radius scales with echelon), never a single cell. A settlement may be strong in several resources at once.

**The Kingdom Capital has `natural_production[r] = 0` for all `r`.** It cannot self-sustain through size; its economic role is service capture (§32, §18).

## 16. Requirements vs Wants

- **Mandatory** (Food, Water, Wood; +Metal/Stone by echelon): shortfall degrades settlement health and, persistently, causes failure.
- **Wants** (Wine, Luxury Goods, Entertainment): affect attractiveness and discretionary activity; never a direct survival condition.

The solver must keep these categories distinct: a settlement whose local production covers its mandatory needs survives indefinitely with zero trade.

## 17. Stockpiles

```text
stockpile_next = clamp(stockpile + production + imports − consumption − exports, 0, storage_capacity)
```

Stockpiles are finite and **never negative** — a shortfall is recorded as unmet demand and a health condition, not as negative inventory. When a stockpile is full, excess production is wasted (idle), and workforce is **not** permanently reduced. A self-sufficient settlement therefore fills its stores, wastes the overflow, and remains stable. This is intended.

## 18. Kingdom Capital

The capital produces no natural resources, carries large mandatory consumption, and funds survival imports from its **treasury** (§33). Its only productive economic output in V1 is **service capture** — it draws discretionary spending from the prosperous settlements it depends on.

The capital is therefore *deliberately fragile*: it is solvent only while the surrounding economy is prosperous enough to spend at it. Administration/politics are named flavor in V1 and carry no mechanic (deferred).

## 19. Attractiveness

```text
attractiveness = base_echelon_attraction × service_factor × wants_satisfaction × stability_factor
```

| Echelon | base_echelon_attraction |
|---|---|
| Hamlet | 0.1 |
| Village | 0.3 |
| Town | 0.6 |
| Walled City | 1.0 |
| Capital | 1.5 |

- `service_factor` — available service capacity (§32).
- `wants_satisfaction` — Wine/Luxury/Entertainment fulfillment.
- `stability_factor` — drops sharply under mandatory shortage or wealth distress, coupling collapse to attractiveness.

Attractiveness is computed from the *completed* month and feeds the *next* month; it never retroactively alters the current month's flows (§35, §7).

---

# PART V — DISTANCE, TRADE & LOGISTICS

## 20. Distance

```text
distance(A,B) = sqrt((Ax−Bx)² + (Ay−By)²)
```

Plain Euclidean, from settlement (or external-market) coordinates. No pathfinding. Graphical route nodes (§22) bend the drawn line only and never affect economic distance.

## 21. Transport Cost

```text
transport_cost = quantity × transport_burden(resource) × distance × transport_cost_constant
```

Emergent consequences (bulk+far = expensive; light+valuable+far = viable; abundance ≠ usefulness) fall out of this one formula combined with §12.

**Transport is paid to an abstract logistics sector outside the modeled settlement economy.** It is therefore a genuine kingdom-level monetary **outflow** with an explicit accounting destination (the boundary), not a silent sink (§27, §29).

## 22. Trade Routes & Endpoints

Routes are directional; A→B and B→A are separate routes. An endpoint is a settlement **or** an external market — external routes reuse the identical machinery.

```text
TradeEndpoint { type: settlement | external_market, id }

TradeRoute {
    id
    source_endpoint, destination_endpoint
    cargo[] { resource, quantity_per_month }
    nodes[]                 # graphical only
    active
    # derived, recomputed on recalc:
    distance, transport_cost, net_trade_value
}
```

No route ever activates automatically. The player approves, modifies, rejects, or deletes every route.

## 23. Export Capacity & Deterministic Allocation

A settlement's total outgoing flow is capped by throughput:

```text
export_capacity = base_capacity(echelon) × workforce_factor × market_factor
```

Domestic and external exports compete for this one pool. External markets have unlimited *import* appetite and unlimited *export* supply, but a settlement selling to them still spends its own finite export capacity.

When requested exports exceed capacity, allocate deterministically by category, then within category:

```text
Category order:
  1. Critical mandatory Food
  2. Critical mandatory Water
  3. Other mandatory resources
  4. Economically profitable exports
  5. Wants / luxuries
Within a category:
  deficit_severity → economic_value → ascending stable route ID
```

Example: capacity 100, requests {Food 60, Water 40, Luxury 30} → {Food 60, Water 40, Luxury 0}.

## 24. Imports & Feasibility

Imports are network-unlimited but bounded by **currency, storage, demand, route quantity, and source availability**. Every import is subject to feasibility validation *before* it settles (§29):

- cannot exceed destination storage headroom,
- cannot exceed source surplus or source export capacity,
- **cannot be funded beyond the buyer's means** (mandatory imports draw on treasury down to zero; discretionary imports draw only on disposable income, §30, §33).

The solver never creates an active route from demand alone; the player must approve it.

## 25. External Economy (the open boundary)

The rest of the world is modeled as one or more **external-market reservoir nodes** pinned past the map edge. Each has infinite supply, infinite appetite, infinite export capacity, a fixed price list, and a position. Its own ledger is **not** counted as kingdom money — it is a bath, not a player, and never renders as a normal settlement.

External trade is ordinary trade: a route to a reservoir pays transport by Euclidean distance to that edge point and competes for export capacity like any route. The reservoir is where kingdom money **enters and leaves** (§27).

**Asymmetric spread** makes foreign trade a frictional fallback, not a default:

```text
external_export_price = base_price × external_export_price_factor   # < 1  (they buy your goods cheap)
external_import_price = base_price × external_import_price_factor   # > 1  (they sell you goods dear)
```

**Tuning constraint (do not violate):** the export factor must stay high enough that a well-placed surplus producer still nets a profit selling abroad after transport — otherwise the money faucet welds shut and the kingdom trends to zero money. Put the discouragement on the **import** (sell) side, which only taxes consumption and never closes the faucet:

```text
external_export_price > cost for an edge surplus-producer to produce and haul   # keep faucet OPEN
external_import_price > domestic base price                                     # steer players to buy at home
```

*Rationale — why this equilibrates:* staple **exports** are production-driven (money enters roughly independent of how rich the kingdom is), while luxury **imports** are wealth-driven (money leaves faster the richer a settlement gets). The mismatch is a restoring force: poor kingdoms take in more than they spend abroad; rich ones spend out; total money settles at a stable fixed point. Multiple reservoirs with different price lists at different edges make *which border a settlement sits near* economically meaningful.

## 26. Recommendation Engine

The engine continuously proposes sensible routes and **never** activates them.

```text
economic_factor      = max(minimum_viability, net_trade_value / gross_trade_value)
recommendation_score = need_priority × deficit_severity × source_surplus_reliability
                       × route_feasibility × economic_factor
```

- Scores on **net** economics (after distance and transport), not gross value.
- Mandatory deficits may override profitability thresholds.
- Prefers a viable **domestic** route over an external one when delivered economics are competitive; recommends external only when domestic supply is absent, inaccessible, insufficient, cheaper-after-costs, an emergency, or a surplus with no domestic outlet.
- Every recommendation carries a suggested quantity and an inspectable reason.

---

# PART VI — MONEY (LEDGER-BASED CORE)

## 27. Monetary Principles

1. **Production creates no money.** Money only moves; it is never minted by making goods.
2. **Domestic transfers conserve money.** Every domestic goods sale and every domestic service payment has a source and a destination *inside* the kingdom; they net to zero kingdom-wide.
3. **The kingdom is economically open.** Money enters and leaves only across the boundary, via exactly three channels:

```text
kingdom_money_delta =
    + external_goods_export_revenue      # in
    − external_goods_import_cost         # out
    + foreign_visitor_income             # in
    − transport_cost_paid                # out
```

4. **No flow disappears.** Every wealth change is the settlement of a ledger entry (§29). Transport's "destination" is the abstract logistics sector at the boundary — named, not vanished.

## 28. Prices

Domestic prices are fixed global base prices in V1, but **callers never hard-code them.** All pricing goes through functions, leaving scarcity/regional pricing as a future drop-in:

```text
get_price(resource, settlement)                 = base_price(resource)               # V1
get_external_export_price(resource, market)     = base_price × export_price_factor
get_external_import_price(resource, market)     = base_price × import_price_factor
```

## 29. The Transaction Ledger — Source of Monetary Truth

**This is the central monetary rule of the game. All of §16-value money movement is expressed here and nowhere else.**

> **Invariant L1 — Ledger completeness:** A settlement's wealth may change *only* by settling a validated ledger entry. There is no other path to a wealth mutation anywhere in the codebase.

Each simulation month builds, validates, then settles a ledger. An entry:

```text
Transaction {
    type            # goods_domestic | goods_external | service_domestic | service_foreign | transport
    source          # settlement id, or BOUNDARY
    destination     # settlement id, or BOUNDARY
    resource        # null for service/transport
    quantity
    gross_value
    boundary_flag   # true if source or destination is BOUNDARY (external market / logistics / foreign visitor)
}
```

Pipeline: **build → validate → settle → derive.**

- **Build** — from cached rates (§34), emit candidate entries for every intended flow: goods routes (domestic + external), service (entertainment) flows, foreign-visitor inflows, and the transport entry attached to each physical shipment.
- **Validate (feasibility lives here, pre-settlement)** — deterministically scale or drop entries, in stable priority order, until *all* of the following hold for every settlement simultaneously:
  - source has the physical surplus to ship,
  - destination has the storage headroom to receive,
  - source export-capacity pool is not exceeded (§23 allocation),
  - service-capacity ceilings are not exceeded (§32),
  - **affordability:** no settlement's settled wealth can go below zero. Mandatory-import entries may draw a buyer's treasury down to (but not below) zero; discretionary entries may draw only on that buyer's disposable income budget (§30).
- **Settle** — apply physical deltas (stockpiles, already clamped feasible ≥ 0) and monetary deltas (each entry moves `gross_value` source→destination; BOUNDARY endpoints are the only net kingdom flows). Because validation guaranteed feasibility, **no clamp is required** to keep wealth non-negative.
- **Derive** — from the settled ledger, compute each settlement's `wealth_delta` components for inspection, and the kingdom_money_delta.

> **Invariant L2 — Conservation by construction:** summed over all entries, every non-`boundary_flag` entry contributes `+gross_value` to one settlement and `−gross_value` to another, so domestic flows net to zero. `Σ settlement wealth_delta = kingdom_money_delta`, and that equals exactly the four boundary channels of §27. This is asserted every month in debug builds; a failure is an implementation bug, not a game state.

> **Invariant L3 — Non-negativity is structural:** `wealth_end ≥ 0` and `stockpile ∈ [0, capacity]` hold because validation enforced them, not because a `max(0, …)` floor repaired them. A firing floor would indicate a validation escape and must fail the test suite.

## 30. Discretionary Spending — Income-Based (keystone rule)

Discretionary spending (entertainment out, plus Wine/Luxury *want* imports) is funded from a settlement's **monthly disposable income — a flow — not from accumulated wealth, a stock.**

```text
monthly_net_productive_income =
      goods_export_revenue (domestic + external)
    − mandatory_goods_import_cost (domestic + external)
    − transport_cost_paid
disposable_income   = max(0, monthly_net_productive_income)
discretionary_budget = disposable_income × discretionary_rate
```

*Rationale — why this is law and not stock-based:* the entire caching and fast-forward architecture (§34, §36) assumes monthly rates are **constant between structural changes**. A budget taken as a fraction of *wealth* changes every month (wealth moves every month), so rates would never be constant and closed-form fast-forward would be mathematically impossible. A budget taken as a fraction of *income* — which is constant between structural changes — keeps every monthly rate constant, makes wealth **piecewise-linear** in months, and restores closed-form boundary leaps. It also (a) makes the treasury-runway projection an honest straight line (§33), (b) stops an idle-rich settlement from bleeding a fixed fraction of its treasury into the nearest theater forever, and (c) means mandatory survival is funded from treasury while luxury is funded only from genuine surplus — the correct priority.

Mandatory imports are **not** discretionary: they are funded from wealth/treasury and are what burns a capital's runway (§33).

**Accepted limitation (idle rich):** a settlement whose wants are fully satisfied and whose luxury imports are maxed simply accumulates wealth. With no banking (§4), V1 has no mechanism to recycle a hoard. This is realistic and bounded, and is left as-is.

## 31. Entertainment Circulation (domestic services)

Entertainment is **money capture**, not creation: prosperous settlements spend disposable income, attractive settlements capture it.

**Route-gated:** a settlement may spend at host `E` only if an active trade route connects them (the trade network is V1's proxy for people traveling). Directional: if only `A→B` exists, `A` may patronize `B`, not vice versa. An isolated settlement cannot capture spending no matter its service capacity.

**Distance-decayed allocation** of a spender's budget across eligible hosts:

```text
accessibility(S,E) = exp(−k × distance(S,E))
weight(S,E)        = attractiveness_E × accessibility(S,E)
service_out(S→E)   = discretionary_budget_S × weight(S,E) / Σ weight(S, all eligible hosts)
```

Each `service_out(S→E)` is a `service_domestic` ledger entry (source S, destination E). Summed kingdom-wide, domestic service spending equals domestic service income (Invariant L2).

## 32. Services & Foreign Visitors (capacity-capped)

V1 services are coarse and macro-scale: **Entertainment** (theater, music, festivals, gambling, taverns — one category; brothels are folded into it explicitly and have no separate math), and **Pilgrimage/religious attraction**, which is the natural home of the foreign-visitor channel below.

**Service capacity is a ceiling shared by domestic and foreign demand.** A settlement absorbs at most `service_capacity` of service spending per month; domestic entertainment (§31) and foreign visitors draw on the *same* pool and are capped together in validation.

```text
service_capacity depends on: echelon, service investment, workforce allocation, tuning.
If total service demand > service_capacity: utilization = 100%, excess demand is dropped (not paid).
```

**Foreign visitors** are a boundary **inflow**: outside money entering when visitors patronize an attractive settlement. It is a `service_foreign` entry (source BOUNDARY, destination E) and is *not* a domestic redistribution.

```text
foreign_visitor_income(E) = min(
    remaining_service_capacity(E),
    foreign_visitor_demand × attractiveness_E × external_market_accessibility(E)
)
```

> **Invariant L4 — the foreign faucet has a governor:** foreign_visitor_income is bounded by remaining service capacity, exactly like domestic service income. There is no uncapped mint. This is the services-side mirror of the goods-side spread constraint (§25).

## 33. Wealth, Runway & Feasibility

A settlement's monthly wealth change, derived from the settled ledger (§29):

```text
wealth_delta =
    + domestic_goods_revenue      − domestic_goods_import_cost
    + domestic_service_income     − domestic_service_spending
    + external_export_revenue     − external_import_cost
    + foreign_visitor_income
    − transport_cost_paid
wealth_end = wealth_start + wealth_delta        # provably ≥ 0 by §29 validation (L3)
```

**Runway.** Because discretionary spend is income-based (§30), monthly burn is well-defined and constant between structural changes, so:

```text
monthly_burn        = max(0, −wealth_delta)
projected_treasury_zero = (monthly_burn > 0) ? wealth / monthly_burn : ∞   # an honest linear projection
```

A newly-upgraded capital loses natural production, so its `wealth_delta` goes negative and its treasury becomes **runway** — time bought to build the network that will feed it service income before the treasury hits zero. This is the core loop:

```text
productive settlements → surplus → wealth → disposable income
    → discretionary spending → capital service income → capital solvency
```

and its failure mirror:

```text
upstream supply fails → supplier income ↓ → supplier disposable income ↓
    → discretionary spending ↓ → capital service income ↓ → capital runway ↓
```

Treasury is runway, never proof of solvency.

---

# PART VII — THE SIMULATION LOOP

## 34. Structural Recalculation & Caching

Expensive spatial work is cached and recomputed only on **structural change**: settlement create/delete/echelon-change, capital designation, route create/delete/quantity/cargo change, resource-field or World-Designer change, external-market config change.

```text
recalculate_world():
   1  validate_world
   2  evaluate_environment_fields          ┐
   3  evaluate_resource_fields             │ spatial layer —
   4  evaluate_settlement_catchments       │ genuinely constant
   5  calculate_workforce                  │ between structural
   6  calculate_natural_production         ┘ changes
   7  calculate_mandatory_consumption
   8  calculate_wants
   9  validate_routes
  10  calculate_distances
  11  calculate_transport_costs
  12  calculate_external_market_prices
  13  allocate_route_capacity
  14  build_goods_flows (domestic + external)
  15  calculate_monthly_net_productive_income   # → disposable income (§30)
  16  calculate_attractiveness / service_capacity
  17  build_service_flows (domestic + foreign), capacity-capped
  18  assemble candidate ledger (rates only, not yet settled)
  19  evaluate_settlement_health
  20  generate_trade_recommendations
  21  publish_economic_state
```

The output is a set of **constant monthly rates** valid until the next structural change.

## 35. The Monthly Tick — `advance_month()`

The month is computed from a frozen start-of-month snapshot and settled through the ledger. No later step may alter a frozen input.

```text
advance_month():
  A. FREEZE      snapshot wealth_start, stockpiles_start; reset monthly accounting accumulators.
  B. BUILD       instantiate this month's candidate ledger from cached rates (§34):
                   goods (domestic+external) + transport entries,
                   service (domestic) + foreign-visitor entries,
                   discretionary want-imports.
  C. VALIDATE    deterministically scale/drop entries until feasibility holds for all settlements
                 simultaneously — surplus, storage, export capacity, service capacity, affordability
                 (§29). This is the ONLY place feasibility is decided.
  D. SETTLE      apply physical deltas (clamp to [0,capacity], already feasible);
                 apply monetary deltas from the validated ledger, once each (no double-charging).
  E. DERIVE      compute wealth_delta components, wealth_end (≥0 by construction),
                 kingdom_money_delta.
  F. EVALUATE    settlement health; then recompute attractiveness/service_capacity/traffic
                 as INPUTS TO NEXT MONTH (never retroactive); compute projections.
  G. BOUNDARIES  detect discrete transitions (§36); flag for recalculation if governing rates change.
  H. ASSERT      run monetary invariants L2/L3 (debug builds).
  I. ADVANCE     increment calendar; publish authoritative state; renderer reads after commit.
```

*Rationale:* the old "settle four piles of money, then also apply a wealth_delta" ordering double-counted transport and could mint money at a wealth floor. The build→validate→settle ledger makes both faults unrepresentable: transport is one entry settled once, and affordability is enforced before any money moves.

## 36. Fast-Forward & State Boundaries

Because §30 makes monthly rates constant between structural changes, wealth and stockpiles are **piecewise-linear**, so fast-forward may leap in closed form to the next boundary rather than stepping month-by-month.

```text
fast_forward():
  1  from cached rates, compute months-until each boundary in closed form
  2  advance to the earliest boundary M*
  3  apply boundary effects; recalculate_world() if governing rates changed
  4  repeat
```

Boundaries (any changes the governing equations): stockpile → 0 or → capacity; wealth → 0; a mandatory import becomes affordable/unaffordable; critical/recovery health threshold crossed; route becomes feasible/infeasible; export- or service-capacity allocation flips.

> The engine must **never** blindly compute "monthly_delta × N" across a boundary. Cache the spatial layer, leap between boundaries, and the result is bit-identical to month-by-month playback (§7).

## 37. Failure & Recovery

Failure emerges from *persistent* shortage; stockpiles buffer transient dips.

| State | Condition |
|---|---|
| Healthy | mandatory covered; stockpiles stable/growing |
| Strained | a mandatory resource trending down |
| Critical | a mandatory stockpile projected to reach zero soon |
| Failed | mandatory unavailable, no sustainable recovery route; severe decline |
| Recovery | positive rates restored; recovers per configured rules |

Failure must be **explanatory**, never an opaque "settlement failed." The UI exposes the causal chain and projections (e.g. "Food reaches zero in 4 months," "Treasury reaches zero in 7 months") and, for cascades, the propagation path (supply loss → stability ↓ → attractiveness ↓ → service income ↓ → wealth ↓).

---

# PART VIII — DATA STRUCTURES & PERSISTENCE

## 38. SettlementState

```text
SettlementState {
    id, name, map_position
    echelon, is_kingdom_capital
    nominal_workforce, productive_workforce
    wealth, wealth_delta_month
    stockpiles[], production_rates[], consumption_rates[]
    imports[], exports[]

    # monetary components (all inspectable; standardized vocabulary):
    domestic_goods_revenue, domestic_goods_import_cost
    domestic_service_income, domestic_service_spending
    external_export_revenue, external_import_cost
    foreign_visitor_income
    transport_cost_paid

    mandatory_status[], wants_status[]
    export_capacity, export_capacity_used
    service_capacity, service_utilization, attractiveness, traffic
    disposable_income, discretionary_budget
    catchment_radius
    projected_treasury_zero
}
```

**Vocabulary is normative.** Use exactly these names. Do not introduce synonyms (`service_revenue`, `entertainment_income`, etc.) — one concept, one identifier, to prevent reconciliation bugs in an agent-built codebase.

## 39. WorldState

```text
WorldState {
    world_id, world_name
    simulation_year, simulation_month
    paused, speed
    map_asset, simulation_grid
    settlements[], trade_routes[], external_economy
    recommendations[]
    economic_version
    random_seed            # reserved, unused
}
```

## 40. TradeRoute, Endpoint & Transaction

As defined in §22 (route/endpoint) and §29 (Transaction). Route `nodes[]` are presentation-only and may never alter economic distance, transport cost, viability, or wealth.

## 41. Save / Load

A save reproduces state exactly and is versioned for future migration:

```text
Save {
    world_id, world_version, schema_version
    simulation_time
    settlements[], trade_routes[], external_economy
    stockpiles, wealth
    resource_fields + resource_field_version
    world_semantic_data
    active_settings
    random_seed
}
```

No event history is required (the sim is deterministic). Load must reproduce identical economic state, including external-economy configuration.

---

# PART IX — INTERFACE & PRESENTATION

## 42. UI, Map, Inspectors, Lenses, Menu, Art

**Look:** a beautiful medieval illustrated/pixel-art map beneath a modern, restrained, software-like interface. Medieval cartography and parchment materiality; readable typography; strong information hierarchy. Avoid generic fantasy-RTS styling and visual noise. The UI is not itself pixel-art.

**Map interaction:** click-drag pans; wheel zooms around the cursor; markers scale and gain detail with zoom (far → geography + major routes; medium → names, ghost routes, indicators; close → local terrain, resource overlay, route geometry). Hover highlights and tooltips; selection opens an inspector and never changes simulation state.

**Settlement creation:** Build tool → placement mode → hover shows a suitability preview (nearby Food/Water/Wood/Metal/Stone potential + expected echelon viability) → click places a Hamlet → `recalculate_world()` → it begins producing. Rename and echelon/capital changes come later.

**Inspectors must explain, not just display numbers:**
- *Settlement* — identity; workforce; physical economy (production/consumption/stockpiles/requirements/wants); trade (imports/exports/capacity/utilization/transport); money (wealth, Δ/month, every monetary component of §38); services (attractiveness, service capacity, utilization, traffic, discretionary budget/spending/income); health (mandatory/wants satisfaction, warnings, projected treasury-zero). Controls: rename, change echelon, capital designation, route list.
- *Route* — endpoints (+external label where applicable), cargo/quantity, distance, transport burden/cost, gross & net value, source/destination wealth effect, capacity usage. Controls: edit cargo/quantity, node add/delete/reorder, delete, apply (→ recalc).
- *Ghost recommendation* — source surplus, destination deficit, distance, transport cost, gross & net value, external spread if relevant, priority/score, and a plain-language **reason**. Controls: establish, modify-then-establish, dismiss.

**Resource lenses:** per-resource continuous heatmap (potential/production/demand/surplus/deficit/stockpile/flow), scarce→abundant legend, markers stay readable, numeric on hover, generated from simulation data (never image-color detection), same renderer as the World Designer.

**Routes render** as bright animated directional white lines (active) and translucent ghost chevrons (recommended); opposite-direction routes render as two distinct flows.

**Main menu:** New World / Load World / World Designer / Settings / Quit. No debug console in normal V1. Confirmation on destructive actions. Clear pause state.

---

# PART X — QUALITY & VALIDATION

## 43. Validation & Monetary Invariants

The validator rejects: negative stockpiles; invalid echelon; more than one Kingdom Capital; missing resource definitions; invalid/nonexistent route endpoints; negative quantities; exports beyond capacity; imports beyond storage/demand; out-of-bounds positions; potentials outside [0,1]; NaN/Infinity anywhere; node edits that would change economic endpoints.

Monetary invariants (asserted every month in debug builds):

```text
L2  Σ domestic_goods_revenue   = Σ domestic_goods_import_cost
    Σ domestic_service_income  = Σ domestic_service_spending
    Σ settlement wealth_delta  = kingdom_money_delta
                               = ext_export_rev − ext_import_cost + foreign_visitor_income − transport_cost_paid
L3  every settlement: wealth_end ≥ 0 and stockpile ∈ [0,capacity] WITHOUT a repairing clamp firing
L1  every wealth change traces to exactly one settled ledger entry
```

## 44. Automated Test Plan

- **Determinism:** same world/seed/decision-sequence → identical state; stable ordering; fast-forward matches month-by-month.
- **Production/stockpiles:** workforce & potential math; capital production = 0; stockpile accounting; non-negative floor; capacity waste.
- **Distance/transport:** Euclidean & symmetric; external-market distance; burden/distance/quantity scaling.
- **Domestic trade:** buyer −gross, seller +gross, seller −transport; goods transaction conserves money; transport recorded as boundary outflow.
- **External trade:** export uses buy-factor and creates inflow; import uses sell-factor and creates outflow; transport accounted; unlimited reservoir.
- **Export capacity:** shared pool; mandatory priority displaces luxury; deterministic ties; domestic vs external compete correctly.
- **Ledger (core):** L1 completeness; L2 conservation; **L3 — construct an unaffordable mandatory import and assert the buyer is scaled to a deficit and the repairing clamp never fires** (this is the regression test for the old money-minting bug); no transport double-charge.
- **Discretionary/services:** income-based budget (not wealth-based); route-gating; distance accessibility; attractiveness weighting; **service_capacity caps domestic + foreign together**; foreign visitor income bounded by remaining capacity.
- **Capital:** production 0; treasury persists through upgrade; monthly burn & projected-zero correct; service income extends runway.
- **Fast-forward:** stops at stockpile/wealth/affordability/service-capacity boundaries; recalculates after governing changes; **bit-identical to stepped playback**.
- **Save/load:** exact round-trip incl. external economy; determinism preserved.

## 45. Benchmark Scenarios

| # | World | Expected |
|---|---|---|
| A | Isolated self-sufficient hamlet | survives forever; stores fill; excess wasted; wealth stays low |
| B | Two complementary neighbors | cheap nearby trade; both beat isolation |
| C | Distant bulk (Stone) | transport dominates; import may be uneconomic; local alternative wins |
| D | Distant luxury | low burden keeps long-distance trade viable |
| E | Capital runway | production→0; Δwealth negative; treasury = runway; service income extends it |
| F | Entertainment gravity | supplier disposable income → city service income |
| G | Network collapse | cut route → deficit → stability↓ → service income↓ → wealth↓ (visible chain) |
| H | External boundary | surplus exports abroad create inflow when revenue > transport; wealthy demand imports create outflow |
| I | Domestic vs external | domestic wins on better delivered economics; external stays selectable |
| J | Closed domestic money | aggregate kingdom money change ≈ −transport outflows only; nothing minted internally |
| K | Foreign visitor inflow | attractive capital draws bounded foreign income; independent of domestic transfers; respects capacity |
| **L** | **Border→interior transmission** | **a single food-exporting border town + a single interior capital, nothing else. Tune border surplus and capital runway until foreign export income, after passing through the disposable-income → service-capture chain (two lossy, lagged hops), actually reaches and stabilizes the capital. If it cannot be made to converge, the money geometry is wrong and must be fixed before UI polish.** |

Scenario L is the load-bearing test for whether the kingdom has a steady state at all; it exercises the full faucet-to-sink path that F/H/K each test only one hop of.

## 46. Performance

Target 60 FPS with hundreds of settlements and thousands of routes. Full recalculation is event-driven, never per-frame. The simulation grid is arrays/data, **never one node per cell**. Overlays render efficiently; static map art loads once. Fast-forward leaps boundaries (§36) rather than grinding months.

---

# PART XI — PROCESS & PRINCIPLES

## 47. AI Agent Rules

Repository docs are authoritative: `AGENTS.md`, `SPEC.md` (this file), `DESIGN_RULES.md`, `ARCHITECTURE.md`, `TODO.md`, `CHANGELOG.md`.

Agents must: read the relevant spec before coding; inspect existing architecture before adding systems; make the smallest coherent change; preserve behavior unless the task changes it; keep simulation independent of presentation; use typed data and centralized tunables; preserve determinism and stable ordering; add/update tests for behavioral changes and run them; inspect the final diff; avoid unrelated refactors; **stop on ambiguity or contradiction rather than inventing mechanics**; never discard user changes, force-reset, or force-push; commit only when explicitly instructed. One agent owns a branch at a time. An independent reviewer (a different model/agent) should review rather than share the implementer's assumptions.

## 48. Development Phases

| Phase | Deliverable |
|---|---|
| 0 | Godot project; world/settlement/resource data; deterministic clock; save/load foundation; tests |
| 0.5 | Solver: production/consumption/stockpiles/wealth; routes/transport/export capacity; external economy; **ledger + monthly tick**; deterministic monthly sim (UI may be ugly) |
| 1 | Playable: map, placement, routes, inspectors, recommendations, sim controls, capital, entertainment economy, external trade |
| 2 | Product polish: menu, presentation, map art, animation, UX, error handling |
| 3 | Validation: automated tests, all benchmark scenarios (esp. J/K/L), long-run & determinism & save/load & performance checks |

## 49. Definition of Done

Product launches as a polished desktop app with menu, save/load, readable explanatory inspectors, no required debug workflow, and runs outside the dev environment. Simulation: settlements/production/consumption/stockpiles/wealth/trade/transport/export-capacity/recommendations/services/entertainment/capital/fast-forward all work deterministically. External economy: reservoir exists; external routes work; export factor < 1 and import factor > 1; external export creates inflow, external import creates outflow, foreign visitors create bounded inflow; transport explicitly accounted; **domestic transfers conserve money; L1/L2/L3 hold; the affordability regression test passes; Scenario L converges.** Architecture: simulation presentation-independent; tunables centralized; state serializable; external economy is a boundary abstraction, not a foreign civilization; tests cover the economic invariants.

## 50. Recommended Initial Tuning Values

All starting points; all live in central config.

```text
Workforce         Hamlet 100 · Village 500 · Town 2,000 · Walled City 10,000 · Capital 25,000
Attraction        Hamlet 0.1 · Village 0.3 · Town 0.6 · Walled City 1.0 · Capital 1.5
Transport burden  Water very high · Stone high/very high · Wood high · Food med/high · Metal med · Wine med · Luxury very low
Resource value    Water very low · Food low · Wood low · Stone low/med · Metal med · Wine med · Luxury very high
Simulation grid   256×128 for ~2048×1024 art
External pricing   external_export_price_factor = 0.75 · external_import_price_factor = 1.25   (subject to §25 faucet constraint)
Tunables to expose  discretionary_rate · reserve_months · entertainment_distance_decay k · transport_cost_constant
                    · external_export_price_factor · external_import_price_factor · foreign_visitor_demand
                    · external_market_accessibility · productivity_constant[r] · base_capacity(echelon)
```

Balance against the benchmark scenarios (§45), not against claims of historical realism.

## 51. Future-Proofing

Leave clean extension points without building them: multiple/regional external markets and variable world prices (replace `ExternalMarket` without touching `TradeRoute`/distance/transport/capacity/recommendation interfaces); scarcity/regional pricing (already routed through `get_price`); terrain-aware transport (consume existing route nodes + terrain geometry); a real transport/carrier sector (turn the transport boundary outflow into a domestic transfer); procedural worldgen (emit the same `WorldPackage`); optional CV map annotation (an authoring aid, never a simulation dependency); seasonal deterministic price oscillation; and later, banking/taxation/administration/military as *explicit* wealth-flow systems layered outside the current formulas — never hidden inside them.

## 52. Final Principles

1. Simulation is independent of presentation.
2. Geography creates productive potential; distance determines its value; transport burden sets how strongly distance bites.
3. Bulk stays local; light and valuable travels.
4. Production creates surplus; surplus creates wealth; wealth creates discretionary spending; attractive settlements capture it.
5. Specialization creates both strength and fragility; the capital is dependent by design.
6. **Money moves only through the ledger; every change traces to one entry; nothing disappears.**
7. Domestic money is conserved; the kingdom is open only at its boundary; the boundary's asymmetry is a restoring force, not a leak.
8. **Discretionary spending scales with income (a flow), never wealth (a stock) — this is what keeps rates constant and makes the whole caching/fast-forward architecture valid.**
9. **Feasibility is enforced before settlement; non-negativity is structural, not a repaired clamp.**
10. Treasury is runway, never proof of solvency.
11. Determinism is mandatory; fast-forward is the same simulation, optimized.
12. Every economic outcome is inspectable; every recommendation is explainable.
13. Prefer the smallest coherent implementation and emergent behavior over scripted outcomes and speculative complexity.

---

## Ultimate V1 Design Statement

> The Medieval Game is a deterministic sandbox whose economy emerges from geography, specialization, distance, logistics, trade, and monetary circulation. Geography creates potential; distance sets its worth; logistics decides which settlements can sustain one another. Surplus becomes wealth; wealth becomes discretionary spending; attractive settlements capture that spending and can survive without producing. Capitals deliberately lack production and live on treasury, trade, and captured service income — treasury is runway, not safety.
>
> Domestic trade and services *redistribute* money; the kingdom is open only at its boundary, where external goods trade, foreign visitors, and logistics payments let money enter and leave — and where an asymmetric spread makes foreign trade a frictional fallback that nonetheless keeps the money supply self-stabilizing. Every coin moves through a validated ledger with an explicit source and destination; nothing is minted by producing goods and nothing vanishes into a void.
>
> Build a kingdom. Understand why it works. Understand why it fails. Watch the consequences unfold.
