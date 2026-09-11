extends GutTest

## Determinism + calendar-arithmetic test for SimulationClock (SPEC §7, §35
## step I). Reproducibility here is a real check (two independently
## constructed WorldStates driven forward), not a tautology against a
## single object.

func _fresh_world() -> WorldState:
	var world: WorldState = WorldState.new()
	world.simulation_year = SimulationClock.STARTING_YEAR
	world.simulation_month = SimulationClock.STARTING_MONTH
	return world


# ---------------------------------------------------------------------------
# Reproducibility — two independent WorldStates, same N, bit-identical result.
# ---------------------------------------------------------------------------

func test_two_independent_clocks_agree_across_boundaries() -> void:
	var months_to_check: Array[int] = [1, 11, 12, 13, 25, 100]

	for n: int in months_to_check:
		var world_a: WorldState = _fresh_world()
		var world_b: WorldState = _fresh_world()

		for _i: int in range(n):
			SimulationClock.advance_one_month(world_a)
		for _i: int in range(n):
			SimulationClock.advance_one_month(world_b)

		assert_eq(
			world_a.simulation_year, world_b.simulation_year,
			"simulation_year diverged after %d months" % n
		)
		assert_eq(
			world_a.simulation_month, world_b.simulation_month,
			"simulation_month diverged after %d months" % n
		)
		assert_eq(
			SimulationClock.total_months(world_a), SimulationClock.total_months(world_b),
			"total_months diverged after %d months" % n
		)


# ---------------------------------------------------------------------------
# Calendar arithmetic — pinned exactly from (year 1, month 1).
# ---------------------------------------------------------------------------

func test_calendar_rollovers_pinned_exactly() -> void:
	var expected: Dictionary = {
		11: [1, 12],
		12: [2, 1],
		13: [2, 2],
		24: [3, 1],
	}

	for n: int in expected.keys():
		var world: WorldState = _fresh_world()
		for _i: int in range(n):
			SimulationClock.advance_one_month(world)

		var expected_year: int = expected[n][0]
		var expected_month: int = expected[n][1]
		assert_eq(world.simulation_year, expected_year, "year after %d months" % n)
		assert_eq(world.simulation_month, expected_month, "month after %d months" % n)


# ---------------------------------------------------------------------------
# Step integrity — no skips, no doubles, month always in range.
# ---------------------------------------------------------------------------

func test_total_months_increases_by_exactly_one_per_step() -> void:
	var world: WorldState = _fresh_world()
	var previous_total: int = SimulationClock.total_months(world)
	assert_eq(previous_total, 0, "total_months at the starting epoch should be 0")

	for k: int in range(1, 101):
		SimulationClock.advance_one_month(world)
		var current_total: int = SimulationClock.total_months(world)
		assert_eq(current_total, previous_total + 1, "total_months should increase by exactly 1 at step %d" % k)
		assert_eq(current_total, k, "total_months should equal step count %d" % k)
		previous_total = current_total


func test_month_is_always_within_valid_range() -> void:
	var world: WorldState = _fresh_world()
	for k: int in range(1, 201):
		SimulationClock.advance_one_month(world)
		assert_true(
			world.simulation_month >= 1 and world.simulation_month <= SimulationClock.MONTHS_PER_YEAR,
			"month %d out of [1, %d] range at step %d" % [world.simulation_month, SimulationClock.MONTHS_PER_YEAR, k]
		)


# ---------------------------------------------------------------------------
# Playback controls never enter the arithmetic.
# ---------------------------------------------------------------------------

func test_paused_and_speed_do_not_affect_the_calendar() -> void:
	var world_default: WorldState = _fresh_world()
	var world_paused_fast: WorldState = _fresh_world()
	world_paused_fast.paused = true
	world_paused_fast.speed = 999.0

	for _i: int in range(13):
		SimulationClock.advance_one_month(world_default)
		SimulationClock.advance_one_month(world_paused_fast)

	assert_eq(world_default.simulation_year, world_paused_fast.simulation_year, "year should be unaffected by paused/speed")
	assert_eq(world_default.simulation_month, world_paused_fast.simulation_month, "month should be unaffected by paused/speed")
