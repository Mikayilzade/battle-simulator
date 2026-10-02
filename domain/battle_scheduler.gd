class_name BattleScheduler
extends RefCounted

static func pending_squad_ids(state: BattleState) -> Array[StringName]:
	var result: Array[StringName] = []
	if state == null or state.outcome != &"ongoing":
		return result
	var first := state.first_side_id if state.round % 2 == 1 else _other_side(state.first_side_id)
	var second := _other_side(first)
	var first_side := _side(state, first)
	var second_side := _side(state, second)
	if first_side == null or second_side == null:
		return result
	var slots := maxi(first_side.squads.size(), second_side.squads.size())
	for index in slots:
		for side in [first_side, second_side]:
			if index >= side.squads.size():
				continue
			var squad: SquadState = side.squads[index]
			if squad.living_member_count() > 0 and not state.activated_squad_ids.has(squad.id):
				result.append(squad.id)
	return result

static func next_activation(state: BattleState, balance: BattleBalanceDef) -> Dictionary:
	if state == null or balance == null or state.outcome != &"ongoing":
		return {"ok": false, "state": state, "error": "battle is missing or finished"}
	if not state.active_squad_id.is_empty():
		return {"ok": false, "state": state, "error": "an activation is already active"}
	var next := state
	var pending := pending_squad_ids(next)
	if pending.is_empty():
		var finished := BattleRules.finish_round(next, balance)
		if not finished["ok"]:
			return finished
		next = finished["state"]
		if next.outcome != &"ongoing":
			return {"ok": true, "state": next, "error": "", "squad_id": &""}
		pending = pending_squad_ids(next)
		if pending.is_empty():
			return {"ok": false, "state": state, "error": "no living squad can activate"}
	var started := BattleRules.start_activation(next, pending[0])
	if not started["ok"]:
		return started
	started["squad_id"] = pending[0]
	return started

static func _other_side(id: StringName) -> StringName:
	return &"red" if id == &"blue" else &"blue"

static func _side(state: BattleState, id: StringName) -> SideState:
	for side in state.sides:
		if side.id == id:
			return side
	return null
