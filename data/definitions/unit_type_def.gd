class_name UnitTypeDef
extends Resource

@export var id: StringName
@export var display_name: String
@export var max_hp: int = 1
@export var armor: int = 0
@export var power: int = 1
@export var movement: int = 1
@export var attack_range: int = 1

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()

	if id.is_empty():
		errors.append("unit type id must not be empty")
	if max_hp <= 0:
		errors.append("max_hp must be greater than 0")
	if armor < 0:
		errors.append("armor must not be negative")
	if power < 0:
		errors.append("power must not be negative")
	if movement < 0:
		errors.append("movement must not be negative")
	if attack_range <= 0:
		errors.append("attack_range must be greater than 0")

	return errors
