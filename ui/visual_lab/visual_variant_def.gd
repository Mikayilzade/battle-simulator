class_name VisualVariantDef
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export_enum("field", "terrain", "unit") var category: String = "field"
@export_enum("2d", "25d", "3d") var mode: String = "2d"
@export var subject: StringName
@export var render_key: StringName

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty() or display_name.is_empty() or render_key.is_empty():
		errors.append("visual variant requires id, display name and render key")
	if category not in ["field", "terrain", "unit"]:
		errors.append("invalid visual category")
	if mode not in ["2d", "25d", "3d"]:
		errors.append("invalid visual mode")
	if category == "terrain" and subject not in [&"plain", &"fields", &"forest", &"hills", &"mountains", &"rough", &"rocks", &"lake", &"sea", &"road"]:
		errors.append("unknown terrain family")
	if category == "unit" and subject not in [&"guard", &"striker", &"archer"]:
		errors.append("unknown unit role")
	return errors
