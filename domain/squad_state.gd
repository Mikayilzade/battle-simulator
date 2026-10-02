class_name SquadState
extends RefCounted

var id: StringName
var side_id: StringName
var unit_type_id: StringName
var position: Vector2i
var members: Array[CombatantState] = []
var front_member_id: StringName
var action_pool: int = 0
var moved_this_activation: bool = false
var attacked_member_ids: Array[StringName] = []
var guarding: bool = false
var is_active: bool = false

func living_member_count() -> int:
	var count := 0
	for member in members:
		if member != null and member.is_living():
			count += 1
	return count
