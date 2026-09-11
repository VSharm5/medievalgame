# AGENTS.md — Operating Manual for AI Agents

This repository is built primarily by AI agents. This file governs **how** you work.
`SPEC.md` governs **what** you build. Read both before touching code.

---

## 0. Authority order

When documents disagree, resolve in this order:

1. `SPEC.md` — authoritative V1 law (behavior, formulas, invariants, vocabulary).
2. `DESIGN_RULES.md` — the binding principles distilled from the spec; the "why" behind the law.
3. `ARCHITECTURE.md` — structure, module boundaries, Godot-specific decisions.
4. `TODO.md` — the phased, gated task backlog.
5. `AGENTS.md` (this file) — process and workflow.
6. Code comments — lowest authority; suspect them.

If `SPEC.md` and any lower document appear to conflict on **substance**, **STOP and ask**. Do not silently reconcile.

---

## 1. The project in one paragraph

The Medieval Game is a **deterministic** economic sandbox for Godot 4.x (2D, GDScript, desktop). A kingdom's economy emerges from geography, settlement specialization, distance, logistics, trade, and monetary circulation. The player builds the physical/political structure and observes consequences; they do not micromanage actors. The load-bearing part of this project is a **headless, deterministic simulation core** whose money is conserved through a single validated ledger. The renderer is secondary.

---

## 2. Prime directives (never violate)

1. **Determinism is mandatory.** Same world + same decision sequence + same elapsed months → **bit-stable** state. No unseeded randomness (V1 uses none at all). Aggregate in **stable-ID order** before any float accumulation. (`SPEC §7`)
2. **Money moves only through the ledger.** A settlement's wealth may change *only* by settling a validated ledger entry (`Invariant L1`). Producing goods mints nothing. (`SPEC §27, §29`)
3. **Discretionary spend scales with income (a flow), never wealth (a stock).** This is what keeps monthly rates constant and makes the caching/fast-forward architecture valid. Reaching for a wealth-based budget breaks the entire engine. (`SPEC §30`)
4. **Feasibility before settlement; non-negativity is structural.** Validation scales/drops entries until every settlement is simultaneously feasible; settlement then applies deltas with **no repairing clamp**. A firing `max(0, …)` on wealth is a bug, not a safeguard. (`SPEC §29`, `Invariant L3`)
5. **Simulation is independent of presentation.** The core never imports a `Node`/`SceneTree`/`Engine`/time/frame API. Presentation reads *published* state and never writes it. (`SPEC §6, §52.1`)
6. **Vocabulary is law.** One concept, one identifier. No synonyms. (`SPEC §38`, and §7 below.)
7. **Stop on ambiguity or contradiction. Never invent mechanics.** (`SPEC §47`)

---

## 3. Workflow (per task)

- **Read first.** Read the relevant `SPEC.md` section(s) before writing code. **Name them** in your commit/PR description.
- **Inspect before adding.** Read `ARCHITECTURE.md` and the actual code before introducing any new system. Prefer extending an existing seam.
- **Smallest coherent change.** Do exactly what the task requires. Preserve all other behavior. No drive-by refactors, no opportunistic renames.
- **Tests are part of the change.** Any behavioral change adds or updates tests and runs the full headless suite. A red suite means the task is **not done**.
- **Review your own diff** before proposing it. Confirm it matches the cited spec section and touches nothing unrelated.
- **Halt on ambiguity.** If the task is unclear, contradicts `SPEC.md`, or would require a mechanic the spec doesn't define — **stop, quote the section, state the ambiguity, propose options, wait.** Guessing is a failure mode here.

---

## 4. Git & collaboration rules

- **One agent owns a branch at a time.** Branch per task or phase slice; keep branches small.
- **Never** discard the user's uncommitted work. **Never** force-reset. **Never** force-push.
- **Commit only when explicitly instructed.** Draft the commit message; do not auto-commit.
- **The reviewer is a different model/agent than the implementer** (`SPEC §47`). The implementing agent must not be the sole reviewer of its own diff. A review pass should re-derive from `SPEC.md`, not inherit the implementer's assumptions.
- Commit messages cite the spec section(s) implemented, e.g. `feat(ledger): build→validate→settle pipeline (SPEC §29, §35)`.

---

## 5. Definition of done (every change)

- [ ] Behavior matches the cited `SPEC.md` section(s).
- [ ] Invariants **L1/L2/L3** hold; debug-build monetary asserts pass (`SPEC §43`).
- [ ] Determinism preserved: stable-ID ordering before float accumulation; **no** new RNG; **no** `Node`/time/frame dependency in the core.
- [ ] Canonical vocabulary used throughout (no synonyms — §7 below).
- [ ] Tests added/updated; full `--headless` suite is green.
- [ ] Fast-forward path (if touched) remains **bit-identical** to month-by-month playback (`SPEC §36`).
- [ ] Diff self-reviewed; nothing unrelated changed.

---

## 6. Hard guardrails — these must FAIL the build / block the PR

These are not style preferences. Each corresponds to a class of bug the spec was written to make unrepresentable.

- A **repairing clamp firing on wealth** — a `max(0, …)` that actually alters a value. This is the money-minting regression; validation must have prevented the shortfall upstream. (`SPEC §29 L3, §44`)
- **Any randomness** — `randf`, `randi`, unseeded RNG, hash-order-dependent iteration used for economic results. V1 is fully deterministic.
- The **simulation core referencing** a Godot `Node`, `SceneTree`, `Engine.get_frames_per_second`, `Time`, `OS`, or any frame/wall-clock value.
- **Presentation or UI writing** to authoritative simulation state.
- Any **domestic** goods or service flow that does **not** net to zero kingdom-wide. (`SPEC §27, Invariant L2`)
- A **synonym** for a canonical field (e.g. `service_revenue`, `entertainment_income`, `city_income`). (`SPEC §38`)
- **Transport double-charging** — transport must be exactly one ledger entry per physical shipment, settled once.
- **Economics inferred from pixels** — the map image is a visual layer only; the sim reads semantic fields, never image colors. (`SPEC §8`)
- **A route activating without explicit player approval.** (`SPEC §22`)

---

## 7. Canonical vocabulary (from `SPEC §38` — do not deviate)

**`SettlementState`:** `id`, `name`, `map_position`, `echelon`, `is_kingdom_capital`, `nominal_workforce`, `productive_workforce`, `wealth`, `wealth_delta_month`, `stockpiles[]`, `production_rates[]`, `consumption_rates[]`, `imports[]`, `exports[]`, `domestic_goods_revenue`, `domestic_goods_import_cost`, `domestic_service_income`, `domestic_service_spending`, `external_export_revenue`, `external_import_cost`, `foreign_visitor_income`, `transport_cost_paid`, `mandatory_status[]`, `wants_status[]`, `export_capacity`, `export_capacity_used`, `service_capacity`, `service_utilization`, `attractiveness`, `traffic`, `disposable_income`, `discretionary_budget`, `catchment_radius`, `projected_treasury_zero`.

**`Transaction`:** `type` ∈ {`goods_domestic`, `goods_external`, `service_domestic`, `service_foreign`, `transport`}, `source`, `destination`, `resource`, `quantity`, `gross_value`, `boundary_flag`. `source`/`destination` are a settlement id or `BOUNDARY`.

**Resources:** `Food`, `Water`, `Wood`, `Metal`, `Stone`, `Wine`, `Luxury Goods`.
**Echelons:** `Hamlet` → `Village` → `Town` → `Walled City` → `Capital-tier`. The `is_kingdom_capital` flag is independent of echelon.

Pricing goes through functions, never literals: `get_price(resource, settlement)`, `get_external_export_price(resource, market)`, `get_external_import_price(resource, market)`. (`SPEC §28`)

All tunables live in central config, never in code paths (`SPEC §50`). Never hard-code a price, factor, or capacity in a formula body.

---

## 8. Commands (conventions — keep in sync with `ARCHITECTURE.md`)

```bash
# Full headless test suite (GUT). The sim core must run with no renderer.
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit

# Run one deterministic benchmark scenario headless (e.g. Scenario L, SPEC §45)
godot --headless --path . -s res://tools/run_scenario.gd -- --scenario=L --months=600

# Determinism check: run a scenario twice and diff the serialized end-state.
godot --headless --path . -s res://tools/determinism_check.gd -- --scenario=L
```

If a command doesn't exist yet, the first task that needs it creates it (see `TODO.md`, Phase 0).

---

## 9. When in doubt

**Stop. Quote the `SPEC.md` section. State the ambiguity. Propose options. Wait for the user.**
A halted task with a good question is a success. A guessed mechanic is a defect.
