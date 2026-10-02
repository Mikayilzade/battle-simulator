class_name VisualLabSelection
extends RefCounted

const NEUTRAL := "neutral"
const FAVORITE := "favorite"
const ARCHIVE := "archive"

var field_id: StringName = &"FIELD-2D-01"
var terrain_ids: Dictionary = {}
var unit_ids: Dictionary = {}
var statuses: Dictionary = {}

func ensure_defaults(catalog: VisualLabCatalog) -> void:
	if catalog.get_variant(field_id) == null:
		var fields := catalog.variants_for("field")
		if not fields.is_empty():
			field_id = fields[0].id
	for family in VisualLabCatalog.FAMILIES:
		if catalog.get_variant(StringName(terrain_ids.get(family, &""))) == null:
			var choices := catalog.variants_for("terrain", family)
			for variant in choices:
				if variant.mode == "2d":
					terrain_ids[family] = variant.id
					break
			if catalog.get_variant(StringName(terrain_ids.get(family, &""))) == null and not choices.is_empty():
				terrain_ids[family] = choices[0].id
	for role in VisualLabCatalog.ROLES:
		if catalog.get_variant(StringName(unit_ids.get(role, &""))) == null:
			var choices := catalog.variants_for("unit", role)
			for variant in choices:
				if variant.mode == "2d":
					unit_ids[role] = variant.id
					break
			if catalog.get_variant(StringName(unit_ids.get(role, &""))) == null and not choices.is_empty():
				unit_ids[role] = choices[0].id

func select(variant: VisualVariantDef) -> void:
	match variant.category:
		"field": field_id = variant.id
		"terrain": terrain_ids[variant.subject] = variant.id
		"unit": unit_ids[variant.subject] = variant.id

func is_selected(variant: VisualVariantDef) -> bool:
	match variant.category:
		"field": return field_id == variant.id
		"terrain": return terrain_ids.get(variant.subject, &"") == variant.id
		"unit": return unit_ids.get(variant.subject, &"") == variant.id
	return false

func status_of(id: StringName) -> String:
	return str(statuses.get(id, NEUTRAL))

func set_status(id: StringName, status: String) -> void:
	if status not in [NEUTRAL, FAVORITE, ARCHIVE]:
		return
	statuses[id] = status
