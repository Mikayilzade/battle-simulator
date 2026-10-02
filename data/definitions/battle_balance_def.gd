class_name BattleBalanceDef
extends Resource

@export var id: StringName
@export var version: StringName
@export var commander_max_hp_bonus: int = 2
@export var commander_power_bonus: int = 1
@export var rear_ranged_power_penalty: int = 2
@export var guard_bonus_armor: int = 1
@export var round_cap: int = 20
@export var squads_per_side: int = 2
@export var members_per_squad: int = 3

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty():
		errors.append("balance id must not be empty")
	if version.is_empty():
		errors.append("balance version must not be empty")
	if commander_max_hp_bonus < 0 or commander_power_bonus < 0:
		errors.append("commander bonuses must not be negative")
	if rear_ranged_power_penalty < 0 or guard_bonus_armor < 0:
		errors.append("rear penalty and guard bonus must not be negative")
	if round_cap <= 0 or squads_per_side <= 0 or members_per_squad <= 0:
		errors.append("round cap and force sizes must be greater than 0")
	return errors
