class_name VisualVariantDef
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export_enum("field", "terrain", "unit", "improvement", "commander") var category: String = "field"
@export_enum("2d", "25d", "3d") var mode: String = "2d"
@export var subject: StringName
@export var render_key: StringName
@export var pack_id: StringName
@export var approach: StringName

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty() or display_name.is_empty() or render_key.is_empty():
		errors.append("visual variant requires id, display name and render key")
	if category not in ["field", "terrain", "unit", "improvement", "commander"]:
		errors.append("invalid visual category")
	if mode not in ["2d", "25d", "3d"]:
		errors.append("invalid visual mode")
	if category == "terrain" and subject not in [&"plain", &"fields", &"forest", &"hills", &"mountains", &"rough", &"rocks", &"lake", &"sea", &"road"]:
		errors.append("unknown terrain family")
	if category == "unit" and subject not in [&"guard", &"striker", &"archer"]:
		errors.append("unknown unit role")
	if category == "improvement" and subject not in [&"lumber", &"farm"]:
		errors.append("unknown improvement")
	if category == "commander" and subject not in [&"banner", &"plume", &"trim"]:
		errors.append("unknown commander cue")
	if not pack_id.is_empty() and mode != "25d":
		errors.append("pack variants must use 25d mode")
	if category == "unit" and not pack_id.is_empty() and approach not in [&"single", &"formation", &"banner"]:
		errors.append("pack unit requires single/formation/banner approach")
	return errors
