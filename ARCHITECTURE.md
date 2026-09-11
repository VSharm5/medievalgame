# ARCHITECTURE.md — Structure & Godot-Specific Decisions

Maps `SPEC.md` Part II–VIII onto a concrete Godot 4.x project. Where the spec defines *what*,
this defines *where it lives* and *how it stays testable and deterministic*.

---

## 1. The one architectural decision everything else hangs on

**The simulation core is plain GDScript classes (`RefCounted`/`Resource`), not `Node`s.**

The core must run under `godot --headless` with no `SceneTree` (`SPEC §6, §7`). Therefore nothing
in `sim/` may extend `Node`, touch the scene tree, read frame/wall-clock time, or import a renderer.
A single thin bridge (`SimulationController`, a `Node`) is the *only* seam between the headless core
and the Godot runtime. This is what makes the invariant/determinism test suite possible.

```
UI  ──commands──▶  SimulationController (Node)  ──drives──▶  Simulation Core (RefCounted, headless)
Presentation  ◀──reads published state──  SimulationController  ◀──publishes──  Simulation Core
```

Dependency direction is strict and one-way: **presentation/UI depend on the core; the core depends on nothing Godot-visual.**

---

## 2. Project layout (`res://`)

```
res://
  sim/                      # HEADLESS core. No Node, no SceneTree, no Time/OS/frame access.
    state/
      world_state.gd            # WorldState (SPEC §39)
      settlement_state.gd       # SettlementState (SPEC §38) — canonical vocabulary
      trade_route.gd            # TradeRoute + TradeEndpoint (SPEC §22, §40)
      external_economy.gd       # ExternalMarket reservoir nodes (SPEC §25)
      resource_fields.gd        # per-cell environmental + resource potential fields (SPEC §10, §11)
      transaction.gd            # Transaction (SPEC §29)
    solver/
      economic_solver.gd        # recalculate_world() pipeline steps 1–21 (SPEC §34)
      world_evaluator.gd        # influences → environment → resource potential (SPEC §9–§11)
      catchment.gd              # settlement catchment sampling (SPEC §15)
      capacity_allocator.gd     # deterministic export-capacity allocation (SPEC §23)
      recommendation_engine.gd  # proposes, never activates (SPEC §26)
    tick/
      monthly_tick.gd           # advance_month() build→validate→settle→derive (SPEC §35)
      ledger.gd                 # TransactionLedger — build/validate/settle/derive (SPEC §29)
      fast_forward.gd           # closed-form boundary leaps (SPEC §36)
    pricing.gd                  # get_price / get_external_* (SPEC §28) — no literals elsewhere
    config/
      tunables.gd               # ALL constants (SPEC §50). Single source of tuning truth.
      resources.gd              # Resource definitions: base_price, transport_burden (SPEC §12)
      echelons.gd               # workforce, attraction, capacity by echelon (SPEC §14, §19, §23)
    invariants.gd               # L1/L2/L3/L4 assertions, called in debug builds (SPEC §43)
  presentation/             # reads published state, NEVER writes it
    map_renderer.gd  settlement_renderer.gd  route_renderer.gd
    resource_lens_renderer.gd  camera.gd
  ui/                       # issues commands to SimulationController, never mutates sim internals
    menus/  top_bar.gd  toolbar.gd  inspectors/  recommendation_panel.gd  sim_controls.gd
    world_designer/
  bridge/
    simulation_controller.gd  # the ONLY Node that owns a core instance; publishes state
  persistence/
    save.gd  load.gd  versioning.gd     # JSON world/save packages (SPEC §41)
  tools/                    # headless entry points for tests & scenarios
    run_scenario.gd  determinism_check.gd
  tests/                    # GUT tests, runnable headless
    unit/  invariants/  scenarios/
  addons/gut/               # test framework
  main.tscn  main_menu.tscn
```

---

## 3. Two entry points + the leap

Everything the core does routes through three functions:

- **`recalculate_world()`** — runs only on **structural change** (settlement create/delete/echelon
  change, capital designation, route change, resource-field/designer change, external-market config
  change). Executes the 21-step pipeline (`SPEC §34`) and emits a set of **constant monthly rates**
  valid until the next structural change. The spatial layer (steps 1–6) is the expensive part and is
  genuinely constant between structural changes — cache it.
- **`advance_month()`** — the monthly tick (`SPEC §35`): `FREEZE → BUILD → VALIDATE → SETTLE →
  DERIVE → EVALUATE → BOUNDARIES → ASSERT → ADVANCE`. Computed from a frozen start-of-month
  snapshot; no later step may mutate a frozen input; attractiveness/service capacity are computed as
  **inputs to next month**, never retroactively.
- **`fast_forward()`** — because rates are constant between structural changes and wealth/stockpiles
  are piecewise-linear, compute months-until each boundary in closed form, leap to the earliest,
  apply boundary effects, `recalculate_world()` if governing rates changed, repeat (`SPEC §36`).
  **Must be bit-identical to stepped playback** — this is a test, not an aspiration.

---

## 4. The ledger pipeline (the monetary heart — `SPEC §29`)

`ledger.gd` owns **build → validate → settle → derive**. This ordering is deliberate and must not be
rearranged:

- **build** — from cached rates, emit candidate `Transaction`s for every intended flow: goods
  (domestic + external), the transport entry attached to each shipment, service (domestic) and
  foreign-visitor entries, discretionary want-imports. Rates only; nothing settled.
- **validate** — the **only** place feasibility is decided. Deterministically scale/drop entries in
  stable priority order until surplus, storage headroom, export capacity (`SPEC §23` allocation),
  service capacity, and **affordability** all hold for every settlement simultaneously.
- **settle** — apply physical deltas (already feasible, clamp to `[0, capacity]`) and monetary deltas
  (each entry moves `gross_value` source→destination, once). **No wealth clamp.** `BOUNDARY` endpoints
  are the only net kingdom flows.
- **derive** — compute each settlement's `wealth_delta` components and `kingdom_money_delta`.

`invariants.gd` asserts **L2** (domestic flows net to zero; `Σ wealth_delta == kingdom_money_delta ==`
the four boundary channels) and **L3** (`wealth_end ≥ 0` and stockpiles in range *without a repairing
clamp firing*) every month in debug builds. A failure is an implementation bug, never a game state.

---

## 5. Determinism mechanics (Godot-specific)

- **Stable-ID ordering.** Before any float accumulation over settlements/routes/resources/ledger
  entries, sort by stable id. Godot 4 `Dictionary` preserves *insertion* order, which is not the same
  as id order — sort explicitly (`SPEC §7`).
- **No nondeterministic sources in `sim/`:** no `randf`/`randi`/`RandomNumberGenerator`, no `Time`,
  `OS`, `Engine.get_frames_per_second`, no `hash()`-order-dependent iteration, no threads accumulating
  floats. `random_seed` exists in state but is **reserved and unused** in V1.
- **Typed GDScript everywhere in `sim/`.** Static typing catches a class of agent errors at parse time
  and satisfies `SPEC §47` "typed data." Enable strict typing warnings as errors project-wide
  (`project.godot` → `debug/gdscript/warnings`: treat `UNTYPED_DECLARATION` and
  `INFERRED_DECLARATION` as errors at minimum). Godot has no per-directory GDScript warning
  configuration, so this setting applies to the whole project, not just `sim/`; `presentation/`,
  `ui/`, etc. inherit the same strictness as a side effect.
- **Fixed monthly step.** The sim advances in discrete months; UI animation/interpolation lives in
  `presentation/` and never feeds back into authoritative state.
- **Floats.** GDScript `float` is 64-bit double; keep all economic math in doubles and never mix in
  frame-time floats. For a single-player deterministic sandbox this is sufficient; do not introduce
  platform-variant fast-math.

---

## 6. Data & state (`SPEC §38–§41`)

`WorldState` holds `settlements[]`, `trade_routes[]`, `external_economy`, `recommendations[]`,
`simulation_year/month`, `economic_version`, grid, map asset, and the reserved `random_seed`.
`SettlementState` uses the **exact** canonical field names (see `AGENTS.md §7`). `TradeRoute.nodes[]`
are **presentation-only** and may never alter economic distance, transport cost, viability, or wealth.

**Config is the single source of tuning truth.** No price, factor, capacity, or rate literal appears
in a formula body — it comes from `config/tunables.gd`, `config/resources.gd`, or `config/echelons.gd`.
Pricing always goes through `pricing.gd` functions so scarcity/regional pricing is a future drop-in.

---

## 7. Persistence (`SPEC §41`)

JSON world/save packages, versioned (`schema_version`, `world_version`, `resource_field_version`).
Load must reproduce **identical** economic state, including external-economy configuration. No event
history is required — the sim is deterministic, so state + config is a complete save. Round-trip
equality is a test (`SPEC §44`).

---

## 8. Presentation & UI rules (`SPEC §42`)

- Presentation reads published state after commit; selection/hover open inspectors and **never**
  change simulation state.
- Resource lenses render from simulation data via the **same** renderer the World Designer previews
  with — never from image-color detection.
- Inspectors must **explain**, not just display: every monetary component of `SPEC §38`, capacity
  utilization, projected treasury-zero, and, on failure, the causal chain.
- Look: illustrated/parchment 2D map under a restrained, modern, software-like UI (the UI is not
  itself pixel-art). Target 60 FPS with hundreds of settlements and thousands of routes; the grid is
  arrays/data, **never one node per cell** (`SPEC §46`).

---

## 9. Testing architecture

- **Framework:** GUT (Godot Unit Test), runnable headless (`AGENTS.md §8`). Any test framework is fine
  as long as it runs under `--headless` and needs no `SceneTree` for `sim/` tests — which it won't,
  because the core is `RefCounted`.
- **Three test tiers** mirror `tests/`:
  - `unit/` — production/stockpile/distance/transport/capacity math (`SPEC §44`).
  - `invariants/` — L1/L2/L3/L4 as executable oracles, plus the **affordability regression test**
    (`SPEC §44`: construct an unaffordable mandatory import; assert the buyer is scaled to a deficit
    and the repairing clamp **never** fires) and the **determinism + fast-forward-equals-stepped**
    checks.
  - `scenarios/` — the benchmark worlds A–L (`SPEC §45`), especially **J** (closed domestic money),
    **K** (bounded foreign inflow), and **L** (border→interior convergence).
- Build the harness **before** features (see `TODO.md`, Phase 0). The invariants are the guardrail
  that lets an agent work a red/green loop instead of generating blind.

---

## 10. Extension seams (leave clean, don't build — `SPEC §51`)

Regional/multiple external markets (swap `ExternalMarket` without touching `TradeRoute`/distance/
transport/capacity/recommendation interfaces); scarcity/regional pricing (already routed through
`get_price`); terrain-aware transport (consume existing route nodes + terrain); a real carrier sector
(turn the transport boundary outflow into a domestic transfer); procedural worldgen (emit the same
`WorldPackage`); seasonal deterministic price oscillation; later banking/taxation/administration/
military as **explicit** wealth-flow systems layered *outside* the current formulas — never hidden
inside them.
