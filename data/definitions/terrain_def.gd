class_name TerrainDef
extends Resource

@export var id: StringName
@export var display_name: String
@export var movement_cost: int = 1
@export var cover: int = 0
@export var blocked: bool = false

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty():
		errors.append("terrain id must not be empty")
	if movement_cost <= 0:
		errors.append("movement_cost must be greater than 0")
	if cover < 0:
		errors.append("cover must not be negative")
	return errors
