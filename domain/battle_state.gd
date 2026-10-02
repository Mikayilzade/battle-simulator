class_name BattleState
extends RefCounted

var schema_version: int = 1
var balance_id: StringName
var map_id: StringName
var round: int = 1
var activation_cursor: int = 0
var active_squad_id: StringName
var activated_squad_ids: Array[StringName] = []
var sides: Array[SideState] = []
var outcome: StringName = &"ongoing"
var seed: int = 0
var rng_state: int = 0
var first_side_id: StringName = &"blue"
