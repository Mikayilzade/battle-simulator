class_name ForcePresetDef
extends Resource

@export var id: StringName
@export var display_name: String
@export var squad_unit_type_ids: PackedStringArray = PackedStringArray()

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty():
		errors.append("force preset id must not be empty")
	if squad_unit_type_ids.is_empty():
		errors.append("force preset must contain squads")
	for type_id in squad_unit_type_ids:
		if type_id.is_empty():
			errors.append("force preset unit type id must not be empty")
	return errors
