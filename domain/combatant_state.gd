class_name CombatantState
extends RefCounted

var id: StringName
var squad_id: StringName
var unit_type_id: StringName
var max_hp: int
var current_hp: int
var is_commander: bool

func is_living() -> bool:
	return current_hp > 0
