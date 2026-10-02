class_name BattleRng
extends RefCounted

const VERSION: int = 1
const MASK: int = 0xffffffff
const ZERO_SEED_STATE: int = 0x6d2b79f5

static func initial_state(seed: int) -> int:
	var value := seed & MASK
	return ZERO_SEED_STATE if value == 0 else value

static func next_u32(current_state: int) -> Dictionary:
	var value := initial_state(current_state)
	value = (value ^ (value << 13)) & MASK
	value = (value ^ (value >> 17)) & MASK
	value = (value ^ (value << 5)) & MASK
	return {"state": value, "value": value}

static func advance(state: BattleState) -> Dictionary:
	if state == null:
		return {"ok": false, "state": state, "error": "battle state is required"}
	var next := BattleRules.copy_state(state)
	var sample := next_u32(next.rng_state)
	next.rng_state = sample["state"]
	return {"ok": true, "state": next, "value": sample["value"], "error": ""}
