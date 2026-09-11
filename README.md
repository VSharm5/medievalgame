# The Medieval Game
A medieval intranational macroeconomy simulator

See `AGENTS.md` for the operating manual and `SPEC.md`/`ARCHITECTURE.md` for the design.

## Running the headless test suite

Requires the Godot 4.x editor binary (`godot`) on `PATH`.

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

`-ginclude_subdirs` is required — `tests/` only contains subdirectories (`unit/`,
`invariants/`, `scenarios/`); without it GUT reports "Nothing was run."
