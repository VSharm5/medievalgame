# CLAUDE.md

This file exists so Claude Code loads the project's operating rules. **The authoritative operating
manual is [`AGENTS.md`](./AGENTS.md).** Read it in full before doing anything.

Document authority order (from `AGENTS.md §0`):
`SPEC.md` → `DESIGN_RULES.md` → `ARCHITECTURE.md` → `TODO.md` → `AGENTS.md` → code comments.

The seven prime directives you must never violate (full text in `AGENTS.md §2`):

1. Determinism is mandatory — bit-stable; no randomness; stable-ID order before float accumulation.
2. Money moves only through the ledger; producing goods mints nothing.
3. Discretionary spend scales with **income (a flow)**, never **wealth (a stock)**.
4. Feasibility is enforced before settlement; non-negativity is structural, not a repair clamp.
5. Simulation is independent of presentation; the core imports no `Node`/`SceneTree`/time/frame API.
6. Vocabulary is law — one concept, one identifier, no synonyms (`SPEC §38`).
7. Stop on ambiguity or contradiction; never invent mechanics.

Before coding: read the relevant `SPEC.md` section, name it in your commit, make the smallest
coherent change, add/run headless tests, and keep the invariant suite green. When unsure, **stop and
ask** — do not guess.

> Keep this file thin. Rules live in `AGENTS.md`; duplicating them here invites drift.
