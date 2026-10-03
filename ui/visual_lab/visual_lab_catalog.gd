class_name VisualLabCatalog
extends RefCounted

const FAMILIES: Array[StringName] = [&"plain", &"fields", &"forest", &"hills", &"mountains", &"rough", &"rocks", &"lake", &"sea", &"road"]
const ROLES: Array[StringName] = [&"guard", &"striker", &"archer"]
const ROOT := "res://ui/visual_lab/variants/"

var variants: Array[VisualVariantDef] = []
var by_id: Dictionary = {}

static func load_catalog() -> VisualLabCatalog:
	var catalog := VisualLabCatalog.new()
	var files := DirAccess.get_files_at(ROOT)
	files.sort()
	for file in files:
		if not file.ends_with(".tres"):
			continue
		var variant := load(ROOT + file) as VisualVariantDef
		if variant != null:
			catalog.variants.append(variant)
			catalog.by_id[variant.id] = variant
	return catalog

func variants_for(category: String, subject: StringName = &"") -> Array[VisualVariantDef]:
	var found: Array[VisualVariantDef] = []
	for variant in variants:
		if variant.category == category and (subject.is_empty() or variant.subject == subject):
			found.append(variant)
	return found

func variants_for_pack(category: String, pack_id: StringName, subject: StringName = &"") -> Array[VisualVariantDef]:
	var found: Array[VisualVariantDef] = []
	for variant in variants:
		if variant.category == category and variant.pack_id == pack_id and (subject.is_empty() or variant.subject == subject):
			found.append(variant)
	return found

func get_variant(id: StringName) -> VisualVariantDef:
	return by_id.get(id) as VisualVariantDef

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen := {}
	var field_modes := {}
	var unit_modes := {}
	for variant in variants:
		if seen.has(variant.id):
			errors.append("duplicate visual variant id %s" % variant.id)
		seen[variant.id] = true
		for error in variant.validation_errors():
			errors.append("%s: %s" % [variant.id, error])
		if variant.category == "field":
			field_modes[variant.mode] = true
		elif variant.category == "unit":
			unit_modes["%s/%s" % [variant.subject, variant.mode]] = true
	for mode in ["2d", "25d", "3d"]:
		if not field_modes.has(mode):
			errors.append("missing field mode %s" % mode)
	for family in FAMILIES:
		if variants_for("terrain", family).is_empty():
			errors.append("missing terrain family %s" % family)
	for role in ROLES:
		for mode in ["2d", "25d", "3d"]:
			if not unit_modes.has("%s/%s" % [role, mode]):
				errors.append("missing unit variant %s/%s" % [role, mode])
	return errors
