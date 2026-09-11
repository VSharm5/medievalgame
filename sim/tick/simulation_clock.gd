extends RefCounted
class_name SimulationClock

## Deterministic monthly calendar (SPEC §35 step I: ADVANCE — "increment
## calendar"). Pure integer arithmetic on WorldState.simulation_year /
## simulation_month (SPEC §39) — no second clock-state object. No Node, no
## Time/OS/Engine/frame access, no randomness (AGENTS.md §6).
##
## WorldState.paused and WorldState.speed (SPEC §39) are playback controls
## for the bridge/UI layer deciding HOW OFTEN to call advance_one_month.
## They are never read here and never enter this arithmetic.

# seeded assumption, SPEC §39 silent
const MONTHS_PER_YEAR: int = 12
# seeded assumption, SPEC §39 silent
const STARTING_YEAR: int = 1
# seeded assumption, SPEC §39 silent
const STARTING_MONTH: int = 1


## Advances the calendar by exactly one month, rolling month -> year at the
## year boundary (SPEC §35 step I).
static func advance_one_month(world: WorldState) -> void:
	world.simulation_month += 1
	if world.simulation_month > MONTHS_PER_YEAR:
		world.simulation_month = 1
		world.simulation_year += 1


## Absolute elapsed-month count since the starting epoch (STARTING_YEAR,
## STARTING_MONTH), for tests/projections.
static func total_months(world: WorldState) -> int:
	return (world.simulation_year - STARTING_YEAR) * MONTHS_PER_YEAR \
		+ (world.simulation_month - STARTING_MONTH)
