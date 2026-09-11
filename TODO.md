# TODO.md — Phased, Gated Task Backlog

Task order follows `SPEC §48`. **Tests come before features**: the invariant suite is the guardrail
that keeps an agentic build from silently breaking money conservation or determinism.

Conventions:
- Each task names the `SPEC.md` section(s) it implements and the test(s) that **gate** it (Definition
  of Done in `AGENTS.md §5`).
- `[ ]` open · `[~]` in progress (one agent, one branch) · `[x]` done (suite green).
- Do the **smallest coherent** task. If a task is ambiguous or contradicts the spec, **stop and ask**.

---

## Phase 0 — Foundation & test harness  *(UI may not exist yet)*

**Goal:** a deterministic clock, typed state, save/load, and a headless test harness with the invariant
oracles in place *before* the solver exists.

- [ ] **0.1 Project skeleton.** Create the `res://` layout from `ARCHITECTURE.md §2`. Enable strict
      typed-GDScript warnings-as-errors for `sim/`. Add GUT under `addons/`. `SPEC §5, §47`.
- [ ] **0.2 Canonical state classes.** `WorldState`, `SettlementState`, `TradeRoute`/`TradeEndpoint`,
      `ExternalMarket`, `ResourceFields`, `Transaction` — as `RefCounted`/`Resource`, using the
      **exact** canonical vocabulary. No `Node` in `sim/`. `SPEC §22, §25, §38–§40`. *Gate:* a schema
      test asserting every canonical field exists with the right type.
- [ ] **0.3 Central config.** `tunables.gd`, `resources.gd`, `echelons.gd` seeded with `SPEC §50`
      values. No literal may appear in any future formula body. `SPEC §12, §14, §19, §23, §50`.
- [ ] **0.4 Deterministic clock + step scaffold.** Month/year advance with no `Time`/`OS`/frame use.
      `SPEC §5, §7`.
- [ ] **0.5 Headless test runner + tools.** `tools/run_scenario.gd`, `tools/determinism_check.gd`,
      and the commands in `AGENTS.md §8`. *Gate:* `--headless` suite runs green with zero tests failing.
- [ ] **0.6 Invariant oracles (skeleton).** `invariants.gd` with L1/L2/L3/L4 assert functions +
      `tests/invariants/` wiring them, initially against trivial fixtures. `SPEC §43`.
- [ ] **0.7 Save/load foundation + round-trip test.** JSON package, versioned; load reproduces
      identical state incl. external economy. `SPEC §41`. *Gate:* round-trip equality test.
      - Must initialize WorldState.simulation_year/simulation_month to the epoch (1, 1); a raw
        WorldState.new() defaults to (0,0), one month before the clock's epoch (flagged in 0.4).
- [ ] **0.8 Determinism harness.** Run a fixed decision sequence twice; assert serialized end-state is
      **bit-identical**. `SPEC §7, §44`. *Gate:* determinism test green.

**Phase 0 exit:** empty-but-typed world loads, saves, reloads identically, and the headless
invariant/determinism harness is green.

---

## Phase 0.5 — Deterministic simulation core  *(the load-bearing phase; UI may be ugly)*

**Goal:** production → consumption → stockpiles → wealth; routes/transport/export capacity; external
economy; the **ledger + monthly tick**; fast-forward. Everything headless and test-gated.

- [ ] **0.5.1 World evaluator.** Influences → environmental fields → resource potential, with
      smoothing. Same math the lens/designer will preview. `SPEC §9–§11`. *Gate:* potential ∈ [0,1],
      no NaN/Inf, deterministic.
- [ ] **0.5.2 Workforce & catchment.** Sublinear productive workforce by echelon; catchment-weighted
      potential sampling. `SPEC §14, §15`. *Gate:* monotonic-specialization test.
- [ ] **0.5.3 Natural production & consumption.** `monthly_production[r]`; mandatory vs wants;
      **Kingdom Capital `natural_production[r] = 0`**. `SPEC §13, §15, §16, §18`. *Gate:* capital
      produces nothing; a settlement covering its own mandatory needs survives with zero trade.
- [ ] **0.5.4 Stockpiles.** `clamp(…, 0, capacity)`; never negative; full → overflow wasted, workforce
      unchanged. `SPEC §17`. *Gate:* self-sufficient hamlet fills, wastes overflow, stays stable
      (Scenario **A**).
- [ ] **0.5.5 Distance & transport.** Euclidean, symmetric; external-market distance; transport =
      `qty × burden × distance × k`. `SPEC §20, §21`. *Gate:* burden/distance/quantity scaling tests.
- [ ] **0.5.6 Export capacity + deterministic allocation.** Shared domestic/external pool; category
      order then deficit_severity → economic_value → ascending stable route id. `SPEC §23`. *Gate:*
      the worked example (`{Food 60, Water 40, Luxury 30}` at cap 100 → `{60,40,0}`) + tie determinism.
- [ ] **0.5.7 External economy reservoir.** Infinite supply/appetite/export-capacity; fixed price
      list; asymmetric spread (export factor `<1`, import factor `>1`) honoring the **faucet-open**
      constraint. Not counted as kingdom money. `SPEC §25`. *Gate:* export creates inflow when revenue
      > transport; import creates outflow; faucet stays open for an edge surplus producer.
- [ ] **0.5.8 Income & disposable income.** `monthly_net_productive_income` → `disposable_income` →
      `discretionary_budget`. **Income-based, never wealth-based.** `SPEC §30`. *Gate:* a test that
      fails if the budget is ever computed from wealth.
- [ ] **0.5.9 Attractiveness & service capacity.** Computed from the completed month as inputs to next
      month; capacity is a ceiling shared by domestic + foreign. `SPEC §19, §32`.
- [ ] **0.5.10 Service flows.** Entertainment: route-gated, directional, distance-decayed allocation;
      `service_domestic` entries net to zero. Foreign visitors: `service_foreign` boundary inflow,
      bounded by remaining capacity (**L4**). `SPEC §31, §32`. *Gate:* Scenario **F**, **K**.
- [ ] **0.5.11 The ledger (core).** `build → validate → settle → derive`. Feasibility (incl.
      affordability) lives **only** in validate; settle applies deltas with **no wealth clamp**.
      `SPEC §29, §35`. *Gate (critical):* **L1** completeness, **L2** conservation, **L3** — the
      **affordability regression test**: construct an unaffordable mandatory import, assert the buyer
      is scaled to a deficit and the repair clamp **never** fires; assert **no transport double-charge**.
- [ ] **0.5.12 Monthly tick.** `advance_month()` FREEZE→…→ADVANCE; attractiveness/capacity as
      next-month inputs; L2/L3 asserted every month in debug. `SPEC §35`. *Gate:* Scenario **J**
      (aggregate kingdom money change ≈ −transport outflows only; nothing minted internally).
- [ ] **0.5.13 Structural recalculation & caching.** `recalculate_world()` 21-step pipeline; recompute
      only on structural change; emit constant monthly rates. `SPEC §34`.
- [ ] **0.5.14 Capital runway.** Upgrade → production 0 → negative `wealth_delta` → treasury = runway;
      `projected_treasury_zero` honest linear projection; service income extends it. `SPEC §18, §33`.
      *Gate:* Scenario **E**.
- [ ] **0.5.15 Fast-forward.** Closed-form boundary leaps (stockpile/wealth/affordability/health/route
      -feasibility/capacity-flip). **Never** `monthly_delta × N` across a boundary. `SPEC §36`. *Gate:*
      **fast-forward is bit-identical to stepped playback** over a long run.
- [ ] **0.5.16 Recommendation engine.** Proposes on **net** economics, prefers viable domestic, never
      activates, every rec has quantity + inspectable reason. `SPEC §26`.
- [ ] **0.5.17 Settlement health.** Healthy/Strained/Critical/Failed/Recovery from *persistent*
      shortage; explanatory causal chain + projections. `SPEC §37`.

**Phase 0.5 exit:** a deterministic month-by-month economy runs headless; L1/L2/L3/L4 hold every
month; fast-forward matches stepped; Scenarios A, E, F, J, K pass. **Scenario L is the gate to Phase 1**
(see below).

---

## ⭐ Scenario L gate — money geometry must converge (`SPEC §45.L`)

Before any UI polish: a single food-exporting border town + a single interior capital, nothing else.
Tune border surplus and capital runway until foreign export income, after passing through the
disposable-income → service-capture chain (two lossy, lagged hops), **actually reaches and stabilizes
the capital**. If it cannot be made to converge, the money geometry is wrong and must be fixed here.

- [ ] **L.1** Build the two-settlement scenario fixture headless.
- [ ] **L.2** Instrument the faucet→sink path (export income → disposable income → service capture →
      capital wealth) so the chain is inspectable.
- [ ] **L.3** Find a tuning point where the capital reaches a stable non-zero steady state; assert
      convergence over a long horizon; confirm bit-identical under fast-forward.

---

## Phase 1 — Playable

**Goal:** map, placement, routes, inspectors, recommendations, sim controls, capital, entertainment
economy, external trade — all wired to the (already correct) core. The Godot editor MCP (`godot-ai`)
becomes useful here for scene wiring and runtime-error feedback; keep it on a feature branch with
destructive auto-approval off.

- [ ] **1.1 Map render + camera.** Pan/zoom-around-cursor; zoom-scaled marker detail. `SPEC §42`.
- [ ] **1.2 Settlement placement.** Build tool → suitability preview → click places a Hamlet →
      `recalculate_world()`. `SPEC §42`.
- [ ] **1.3 Route creation/approval/reject/delete.** Directional; endpoints settlement or external;
      **no auto-activation**. `SPEC §22`.
- [ ] **1.4 Inspectors that explain.** Settlement / Route / Ghost-recommendation, every monetary
      component + projections + causal chain. `SPEC §42`.
- [ ] **1.5 Resource lenses.** Continuous heatmaps from sim data (same renderer as designer), never
      image-color detection. `SPEC §42`.
- [ ] **1.6 Sim controls.** Pause/speed, deterministic fast-forward, month stepping. `SPEC §7, §36`.
- [ ] **1.7 Capital designation & echelon changes** via inspector. `SPEC §13, §18`.
- [ ] **1.8 Route rendering.** Active bright directional lines; translucent ghost chevrons;
      opposite-direction routes as two flows. `SPEC §42`.

---

## Phase 2 — Product polish

- [ ] **2.1 Main menu** (New World / Load World / World Designer / Settings / Quit); pause state;
      confirmation on destructive actions; no debug console in normal V1. `SPEC §42`.
- [ ] **2.2 World Designer** as a first-class tool: influence brushes (radius/strength/falloff/
      hardness/erase), live lens preview using the game renderer. `SPEC §9`.
- [ ] **2.3 Map art pipeline** (load once, reuse); parchment/illustrated look under restrained UI.
      `SPEC §42, §46`.
- [ ] **2.4 Animation, UX, error handling**; runs outside the dev environment. `SPEC §49`.

---

## Phase 3 — Validation

- [ ] **3.1 Full automated suite** per `SPEC §44` green in CI-style headless run.
- [ ] **3.2 All benchmark scenarios A–L** pass, especially **J/K/L**. `SPEC §45`.
- [ ] **3.3 Long-run stability, determinism, save/load, performance** (60 FPS w/ hundreds of
      settlements, thousands of routes; recalculation event-driven, never per-frame). `SPEC §46`.
- [ ] **3.4 Definition of Done review** against `SPEC §49`.

---

## Backlog / explicitly deferred (do NOT build in V1 — `SPEC §4, §51`)

Military, diplomacy, demographics/migration, production chains, banking/loans/taxation/tariffs,
professions/personal services, pathfinding, spoilage, seasons, tech/unlocks, foreign
governments/populations, CV map annotation. Leave the extension seams in `ARCHITECTURE.md §10` clean;
build none of them.
