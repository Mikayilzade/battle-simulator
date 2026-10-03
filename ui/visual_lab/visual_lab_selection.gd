class_name VisualLabSelection
extends RefCounted

const NEUTRAL := "neutral"
const FAVORITE := "favorite"
const ARCHIVE := "archive"

var field_id: StringName = &"FIELD-2D-01"
var pack_id: StringName = &"PACK-25D-A"
var terrain_ids: Dictionary = {}
var unit_ids: Dictionary = {}
var improvement_ids: Dictionary = {}
var commander_id: StringName = &"COMMANDER-25D-BANNER-01"
var preview_state: StringName = &"selected"
var detail_level: StringName = &"medium"
var unit_scale: StringName = &"medium"
var camera_angle: StringName = &"balanced"
var statuses: Dictionary = {}

func ensure_pack_defaults(catalog: VisualLabCatalog, packs: VisualPackCatalog) -> void:
	if packs.get_pack(pack_id) == null:
		pack_id = VisualPackCatalog.REQUIRED_IDS[0]
	var current_plain := catalog.get_variant(StringName(terrain_ids.get(&"plain", &"")))
	if current_plain == null or current_plain.pack_id.is_empty():
		select_pack(pack_id, catalog, packs)

func select_pack(id: StringName, catalog: VisualLabCatalog, packs: VisualPackCatalog) -> bool:
	if packs.get_pack(id) == null:
		return false
	pack_id = id
	terrain_ids.clear()
	unit_ids.clear()
	improvement_ids.clear()
	for family in VisualLabCatalog.FAMILIES:
		var items := catalog.variants_for_pack("terrain", id, family)
		if not items.is_empty():
			terrain_ids[family] = items[0].id
	for role in VisualLabCatalog.ROLES:
		for variant in catalog.variants_for_pack("unit", id, role):
			if variant.approach == &"formation":
				unit_ids[role] = variant.id
				break
	for site in [&"lumber", &"farm"]:
		var items := catalog.variants_for_pack("improvement", id, site)
		if not items.is_empty():
			improvement_ids[site] = items[0].id
	return true

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
		"improvement": improvement_ids[variant.subject] = variant.id
		"commander": commander_id = variant.id

func is_selected(variant: VisualVariantDef) -> bool:
	match variant.category:
		"field": return field_id == variant.id
		"terrain": return terrain_ids.get(variant.subject, &"") == variant.id
		"unit": return unit_ids.get(variant.subject, &"") == variant.id
		"improvement": return improvement_ids.get(variant.subject, &"") == variant.id
		"commander": return commander_id == variant.id
	return false

func status_of(id: StringName) -> String:
	return str(statuses.get(id, NEUTRAL))

func set_status(id: StringName, status: String) -> void:
	if status not in [NEUTRAL, FAVORITE, ARCHIVE]:
		return
	statuses[id] = status
