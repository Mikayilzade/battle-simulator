class_name VisualPackDef
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export_enum("clean", "cozy", "civ", "storybook") var render_key: String = "clean"
@export var ground_color: Color = Color("#849c65")
@export var edge_color: Color = Color("#667c54")
@export var shadow_color: Color = Color("#21342a")
@export var accent_color: Color = Color("#edd89f")
@export_range(0.0, 1.0) var detail_amount: float = 0.5
@export_range(0.0, 1.0) var edge_strength: float = 0.3
@export_range(0.0, 1.0) var shadow_strength: float = 0.3
@export_range(0.3, 1.5) var figure_proportion: float = 1.0

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty() or display_name.is_empty():
		errors.append("pack requires stable ID and display name")
	if render_key not in ["clean", "cozy", "civ", "storybook"]:
		errors.append("unknown pack renderer")
	if not id.begins_with("PACK-25D-"):
		errors.append("pack ID must use PACK-25D- prefix")
	return errors
