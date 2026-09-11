# DESIGN_RULES.md — The Binding Laws

These are the non-negotiable design principles behind the mechanics. `SPEC.md` is the letter
of the law; this file is its intent. When a formula in `SPEC.md` and a principle here seem to
diverge, the formula wins on behavior — but a divergence usually means you've misread one of them,
so **stop and check** rather than reconcile silently.

Each law lists the spec reference and, where agents commonly go wrong, a **⚠ Wrong instinct** note.

---

## The theses (memorize these)

- **Central thesis.** *Do not simulate medieval life. Simulate the logistical consequences of medieval settlement.* (`SPEC §1`)
- **Economic thesis.** *Geography creates productive potential; distance determines what that potential is worth elsewhere.* (`SPEC §1`)
- **Player experience.** Build a kingdom. Understand why it works. Understand why it fails. Watch the consequences unfold. (`SPEC §2`)

Emergent goals must arise from the rules, never from scripting: bulk stays local, light+valuable travels far; a rich but distant settlement can be irrelevant; big specialized settlements become import-dependent and fragile; wealth comes from capturing discretionary spending, not only producing; the money supply self-stabilizes across the boundary; networks beat isolated abundance; failure propagates along visible causal chains. (`SPEC §2`)

---

## Law 1 — Determinism is the foundation

Same world, same decisions, same elapsed months → **bit-stable** state. No unseeded randomness (V1: none). Every aggregation over routes/settlements/resources/ledger iterates in **stable-ID order before any float accumulation**. Every allocation resolves by defined deterministic priority with a stable-ID final tiebreak. Fixed steps; no frame-rate dependence; animation never touches authoritative state. (`SPEC §7`)

⚠ **Wrong instinct:** summing a `Dictionary`/`Array` in whatever order it happens to arrive. Sort by id first.

---

## Law 2 — Money moves only through the ledger; nothing is minted, nothing vanishes

Production creates **no** money. Money only moves, and only by settling a validated `Transaction` (**L1: ledger completeness**). Domestic transfers conserve money — every domestic goods sale and service payment has a source and destination *inside* the kingdom and nets to zero (**L2: conservation**). The kingdom is open **only** at its boundary, through exactly four channels: external export revenue (in), external import cost (out), foreign-visitor income (in), transport cost paid (out). Transport is paid to an abstract logistics sector *at the boundary* — named, not vanished. (`SPEC §27, §29`)

⚠ **Wrong instinct:** giving a settlement wealth when it produces goods, or letting transport "disappear" as an untracked sink. Both violate L1/L2.

---

## Law 3 — Discretionary spending scales with **income**, not **wealth** (keystone)

Discretionary spending (entertainment out + Wine/Luxury *want* imports) is funded from **monthly disposable income (a flow)**, never from accumulated wealth (a stock):

```
disposable_income    = max(0, goods_export_revenue − mandatory_goods_import_cost − transport_cost_paid)
discretionary_budget = disposable_income × discretionary_rate
```

This is **law, not preference.** The entire caching and fast-forward architecture assumes monthly rates are constant between structural changes. A budget taken as a fraction of *wealth* changes every month (wealth moves every month), so rates would never be constant and closed-form fast-forward becomes mathematically impossible. Income is constant between structural changes → rates stay constant → wealth is piecewise-linear in months → boundary leaps are closed-form. It also makes treasury runway an honest straight line, stops an idle-rich settlement from bleeding its treasury forever, and correctly funds mandatory survival from treasury while funding luxury only from genuine surplus. Mandatory imports are **not** discretionary — they draw on wealth/treasury and are what burns a capital's runway. (`SPEC §30`)

⚠ **Wrong instinct:** "spend a fraction of your money on luxuries." That is wealth-based and it silently destroys determinism and fast-forward. Always income-based.

---

## Law 4 — Feasibility is enforced *before* settlement; non-negativity is structural

Each month: **build → validate → settle → derive.** Validation deterministically scales or drops entries, in stable priority order, until *every* settlement is simultaneously feasible — source has physical surplus, destination has storage headroom, export-capacity pool not exceeded, service-capacity ceilings not exceeded, and **affordability** (no settled wealth below zero; mandatory imports may draw treasury to zero, discretionary only from disposable income). Settlement then applies deltas that are already feasible, so **no clamp is needed to keep wealth ≥ 0** (**L3**). Stockpiles are clamped to `[0, capacity]` only because they were already validated feasible. (`SPEC §29, §35`)

⚠ **Wrong instinct:** letting a transaction overdraw and then `max(0, wealth)` afterward. A firing repair clamp is the money-minting regression (`SPEC §44` has the explicit test). Fix feasibility in **validate**, never in **settle**.

---

## Law 5 — Geography is authored semantically, never read from pixels

The imported map image is a **visual layer only**. The simulation reads continuous semantic fields (moisture, fertility, forestability, rockiness, mineralization, dryness, elevation) authored via influence brushes and evaluated into resource potential. It never infers economic properties from image colors. The World Designer previews potential with the **same** lens renderer the game uses. (`SPEC §8, §9, §10, §11`)

⚠ **Wrong instinct:** sampling the PNG to decide what a region produces. Never.

---

## Law 6 — Value and transport burden are independent; distance sets worth

`transport_cost = quantity × transport_burden(resource) × distance × transport_cost_constant`, distance is plain Euclidean between coordinates (no pathfinding; graphical route nodes bend the drawn line only). Because a resource's **value** and its **transport burden** are independent axes, emergent trade geography falls out for free: Water is cheap but crippling to move; Luxury is precious but light. Abundance ≠ usefulness. (`SPEC §12, §20, §21`)

---

## Law 7 — The boundary spread is a restoring force, not a leak

External export price factor `< 1` (they buy your goods cheap); external import price factor `> 1` (they sell you goods dear). **Tuning constraint you may not violate:** the export factor must stay high enough that a well-placed edge surplus-producer still nets a profit after transport — otherwise the money faucet welds shut and the kingdom trends to zero money. Put the discouragement on the **import** side. Staple exports are production-driven (money in, roughly independent of kingdom wealth); luxury imports are wealth-driven (money out, faster the richer you are). The mismatch pulls total money to a stable fixed point. (`SPEC §25`)

⚠ **Wrong instinct:** cranking the export factor down "for challenge." That closes the faucet and the economy dies. Discourage imports, never exports.

---

## Law 8 — Services capture money; every faucet has a governor

Entertainment is money **capture**, not creation: prosperous settlements spend disposable income; attractive settlements capture it, **route-gated** (spend only where an active route connects, directional) and **distance-decayed**. Foreign visitors are a boundary **inflow**, but bounded by remaining service capacity exactly like domestic service demand — domestic and foreign draw on the **same** capped pool (**L4**: no uncapped mint). (`SPEC §31, §32`)

---

## Law 9 — Specialization is strength and fragility; the capital is dependent by design

Productive workforce grows **sublinearly** with echelon (bigger settlements spend more of their labor on baseline function), so large settlements are import-dependent, not strictly better. The Kingdom Capital has **zero** natural production; its only economic output is **service capture**, and it survives on **treasury as runway** while it builds the network that will feed it. Treasury is runway, never proof of solvency. (`SPEC §14, §15, §18, §33`)

---

## Law 10 — Simulation is independent of presentation

The core is headless and testable with no renderer attached. Presentation reads authoritative state after commit and never mutates it. UI issues commands to a controller; it never reaches into simulation internals. (`SPEC §6, §52.1`)

---

## Law 11 — Fast-forward is the *same* simulation, optimized

Because rates are constant between structural changes (Law 3), wealth and stockpiles are piecewise-linear, so fast-forward leaps in closed form to the next boundary. It must produce state **bit-identical** to month-by-month playback. **Never** compute `monthly_delta × N` across a boundary. (`SPEC §36`)

---

## Law 12 — Everything is inspectable; every recommendation is explainable

Failure is never an opaque "settlement failed." The UI exposes the causal chain and honest linear projections ("Food reaches zero in 4 months"; "Treasury reaches zero in 7 months") and, for cascades, the propagation path. The recommendation engine proposes routes and **never** activates them; every recommendation carries a suggested quantity and an inspectable, plain-language reason, scored on **net** economics. (`SPEC §26, §37`)

---

## What V1 is NOT (do not build these — `SPEC §4`)

No military/warfare/armies/diplomacy; no individual citizens/demographics/births/deaths/migration; no detailed production chains; no banking/loans/interest/debt/taxation/tariffs; no individual professions or personal services; no terrain pathfinding; no spoilage/perishability; no seasons; no tech/unlocks/campaign progression; no foreign governments/populations (the external economy is a deliberate **abstraction**, a bath, not a simulated neighbor). Because there is no debt, **affordability is a hard pre-settlement constraint** — there is no borrowing to paper over a shortfall.

If a task seems to need one of these to work, the design is being misread — **stop and ask.**

---

## Balancing philosophy

Tune against the **benchmark scenarios** (`SPEC §45`), not against claims of historical realism. Constants in `SPEC §50` are starting points and live in central config. Scenario **L** (border→interior transmission) is the load-bearing convergence test: if foreign export income cannot travel the disposable-income → service-capture chain and stabilize the capital, the money geometry is wrong and must be fixed **before** UI polish.
