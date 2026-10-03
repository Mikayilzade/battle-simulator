class_name VisualPackCatalog
extends RefCounted

const ROOT := "res://ui/visual_lab/packs/"
const REQUIRED_IDS: Array[StringName] = [&"PACK-25D-A", &"PACK-25D-B", &"PACK-25D-C", &"PACK-25D-D"]

var packs: Array[VisualPackDef] = []
var by_id: Dictionary = {}

static func load_catalog() -> VisualPackCatalog:
	var catalog := VisualPackCatalog.new()
	var files := DirAccess.get_files_at(ROOT)
	files.sort()
	for file in files:
		if not file.ends_with(".tres"):
			continue
		var pack := load(ROOT + file) as VisualPackDef
		if pack != null:
			catalog.packs.append(pack)
			catalog.by_id[pack.id] = pack
	return catalog

func get_pack(id: StringName) -> VisualPackDef:
	return by_id.get(id) as VisualPackDef

func validation_errors(variants: VisualLabCatalog) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen := {}
	for pack in packs:
		if seen.has(pack.id):
			errors.append("duplicate pack ID %s" % pack.id)
		seen[pack.id] = true
		for error in pack.validation_errors():
			errors.append("%s: %s" % [pack.id, error])
	for id in REQUIRED_IDS:
		if not by_id.has(id):
			errors.append("missing pack %s" % id)
	for variant in variants.variants:
		if not variant.pack_id.is_empty() and not by_id.has(variant.pack_id):
			errors.append("%s references unknown pack %s" % [variant.id, variant.pack_id])
	for pack in packs:
		for family in VisualLabCatalog.FAMILIES:
			if variants.variants_for_pack("terrain", pack.id, family).is_empty():
				errors.append("%s missing terrain %s" % [pack.id, family])
		for role in VisualLabCatalog.ROLES:
			var approaches := {}
			for unit in variants.variants_for_pack("unit", pack.id, role):
				approaches[unit.approach] = true
			for approach in [&"single", &"formation", &"banner"]:
				if not approaches.has(approach):
					errors.append("%s missing %s/%s" % [pack.id, role, approach])
		for site in [&"lumber", &"farm"]:
			if variants.variants_for_pack("improvement", pack.id, site).is_empty():
				errors.append("%s missing improvement %s" % [pack.id, site])
	return errors
