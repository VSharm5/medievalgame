extends RefCounted
class_name Transaction

## Canonical ledger entry vocabulary (SPEC §29). Structure only — no
## build/validate/settle/derive logic (that is sim/tick/ledger.gd, a later
## task).
##
## `resource` is typed Variant, not SimEnums.ResourceType, because SPEC §29
## states it is null for service/transport entries. Adding a synthetic
## "none" member to ResourceType would corrupt the canonical 7-resource set
## (SPEC §12) used to iterate every other resource-keyed field in this
## package, so Variant is the accurate typing for a field the spec itself
## declares nullable, not an untyped/inferred declaration.

var type: SimEnums.TransactionType
var source: String
var destination: String
var resource: Variant = null
var quantity: float
var gross_value: float
var boundary_flag: bool = false
