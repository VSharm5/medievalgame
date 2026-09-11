# Changelog

All notable changes to The Medieval Game are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project is deterministic and pre-release; versions track development phases (`SPEC §48`)
until a tagged V1.

Agents: add an entry under **[Unreleased]** for every behavioral change, cite the `SPEC.md`
section(s), and note any invariant/test added. Do not rewrite history.

## [Unreleased]

### Added
- Repository documentation set for AI-agent development: `AGENTS.md`, `DESIGN_RULES.md`,
  `ARCHITECTURE.md`, `TODO.md`, `CHANGELOG.md` (`SPEC.md` is the authoritative V1 spec).

### Changed
- _nothing yet_

### Fixed
- _nothing yet_

---

<!--
Template for a phase/version release once tagged:

## [0.5.0] — YYYY-MM-DD  — Deterministic simulation core
### Added
- Ledger build→validate→settle→derive pipeline (SPEC §29, §35); invariants L1/L2/L3 asserted monthly.
- Fast-forward closed-form boundary leaps, bit-identical to stepped playback (SPEC §36).
### Changed
### Fixed
- Affordability regression: unaffordable mandatory import now scaled in validate; repair clamp
  never fires (SPEC §29 L3, §44).
-->
