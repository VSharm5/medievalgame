extends RefCounted
class_name ExternalMarket

## Canonical external-market reservoir vocabulary (SPEC §25). Structure only.
## Infinite supply/appetite/export-capacity are behavioral facts (SPEC §25),
## not stored fields, since they are not tunable finite quantities. Price
## FACTORS (export/import spread, base prices) are config (task 0.3) and do
## not belong here — `price_list` is only the structural container that
## config will populate; it deliberately has no zero-filled default (unlike
## SettlementState's flow dictionaries, 0.0 would misrepresent "no price set"
## as "priced at zero").

var id: String
var map_position: Vector2
var price_list: Dictionary[SimEnums.ResourceType, float] = {}
