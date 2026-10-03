extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var catalog := VisualLabCatalog.load_catalog()
	var packs := VisualPackCatalog.load_catalog()
	var authored_files := 0
	for file in DirAccess.get_files_at(VisualLabCatalog.ROOT):
		if file.ends_with(".tres"):
			authored_files += 1
	_check(catalog.variants.size() == authored_files, "every authored visual resource loads")
	_check(packs.packs.size() == 4, "four authored isometric packs load")
	_check(catalog.variants.size() >= 121, "old and new visual variants resolve")
	_check(catalog.validation_errors().is_empty(), "variant IDs and definitions validate: %s" % catalog.validation_errors())
	_check(packs.validation_errors(catalog).is_empty(), "all packs are complete: %s" % packs.validation_errors(catalog))
	for id in VisualPackCatalog.REQUIRED_IDS:
		_check(packs.get_pack(id) != null, "%s resolves" % id)
		for family in VisualLabCatalog.FAMILIES:
			_check(catalog.variants_for_pack("terrain", id, family).size() >= 1, "%s has %s" % [id, family])
		for role in VisualLabCatalog.ROLES:
			_check(catalog.variants_for_pack("unit", id, role).size() == 3, "%s has three %s approaches" % [id, role])
	var main := load("res://ui/main/Main.tscn").instantiate() as Control
	root.add_child(main)
	await process_frame
	_check(main.screen.scene_file_path == "res://ui/setup/Setup.tscn", "main opens setup")
	var setup_config: Dictionary = main.screen.build_config()
	main.screen.lab_requested.emit(setup_config)
	await process_frame
	var lab: Control = main.screen
	_check(lab.scene_file_path == "res://ui/visual_lab/VisualLab.tscn", "setup opens visual lab")
	_check(lab.tabs.tab_count == 5, "five comparison sections exist")
	_check(lab.preview.size.x >= 780 and lab.preview.size.y >= 480, "map dominates comparison stage")
	_check(lab.selection.pack_id == &"PACK-25D-A", "default coherent pack is A")
	for id in VisualPackCatalog.REQUIRED_IDS:
		_check(lab.select_pack(id), "preview accepts %s" % id)
		await process_frame
		_check(lab.preview.selection.pack_id == id, "diorama displays %s" % id)
		_check(lab.selection.terrain_ids[&"forest"] == StringName("TERRAIN-FOREST-25D-%s01" % id.right(1)), "pack swaps forest visual")
		_check(lab.selection.unit_ids[&"archer"] == StringName("UNIT-ARCHER-25D-%s02" % id.right(1)), "pack swaps archer formation")
	_check(lab.select_variant(&"TERRAIN-FOREST-25D-B01"), "terrain can override selected pack")
	_check(lab.select_variant(&"UNIT-GUARD-25D-C03"), "unit approach can override selected pack")
	_check(lab.select_variant(&"IMPROVEMENT-LUMBER-25D-B01"), "work site can override selected pack")
	_check(lab.select_variant(&"COMMANDER-25D-PLUME-01"), "commander cue can change")
	_check(lab.selection.terrain_ids[&"forest"] == &"TERRAIN-FOREST-25D-B01" and lab.selection.unit_ids[&"guard"] == &"UNIT-GUARD-25D-C03", "combined overrides remain independent")
	lab.tabs.current_tab = 1
	lab.terrain_filter = &"lumber"
	lab._refresh_list()
	_check(lab.list.get_child_count() >= 6, "terrain library includes work-site choices")
	lab.tabs.current_tab = 3
	lab._refresh_list()
	_check(lab.terrain_filter == &"plain", "combined preview restores a valid terrain family")
	_check(_select_labelled_option(lab, "Detail density", 2) and lab.selection.detail_level == &"high", "density picker changes preview")
	_check(_select_labelled_option(lab, "Unit scale", 0) and lab.selection.unit_scale == &"small", "unit-scale picker changes preview")
	_check(_select_labelled_option(lab, "Camera angle", 2) and lab.selection.camera_angle == &"strong", "camera-angle picker changes preview")
	_check(_select_labelled_option(lab, "Preview state", 4) and lab.selection.preview_state == &"route", "scenario picker changes preview")
	for state in [&"normal", &"selected", &"reachable", &"target", &"route", &"damaged", &"dense"]:
		lab.set_preview_state(state)
		await process_frame
		_check(lab.preview.selection.preview_state == state, "preview state %s" % state)
	for level in [&"low", &"medium", &"high"]:
		lab.selection.detail_level = level
		lab.preview.queue_redraw()
		await process_frame
	for scale_value in [&"small", &"medium", &"large"]:
		lab.selection.unit_scale = scale_value
		lab.preview.queue_redraw()
		await process_frame
	for angle in [&"top", &"balanced", &"strong"]:
		lab.selection.camera_angle = angle
		lab.preview.queue_redraw()
		await process_frame
	_check(lab.mark_variant(&"PACK-25D-B", VisualLabSelection.FAVORITE), "pack can be shortlisted")
	_check(lab.mark_variant(&"UNIT-ARCHER-25D-B03", VisualLabSelection.ARCHIVE), "unit variant can be archived")
	_check(lab.selection.status_of(&"PACK-25D-B") == VisualLabSelection.FAVORITE, "favorite status retained")
	_check(lab.catalog.get_variant(&"UNIT-ARCHER-25D-B03") != null and lab.select_variant(&"UNIT-ARCHER-25D-B03"), "archive remains browsable/selectable")
	lab.exit_requested.emit(setup_config)
	await process_frame
	_check(main.screen.scene_file_path == "res://ui/setup/Setup.tscn", "return restores setup")
	_check(main.screen.build_config() == setup_config, "battle setup remains unchanged")
	main.screen.lab_requested.emit(setup_config)
	await process_frame
	_check(main.screen.selection.pack_id == &"PACK-25D-D" and main.screen.selection.status_of(&"PACK-25D-B") == VisualLabSelection.FAVORITE, "session selection survives reentry")
	print("Isometric Visual Lab tests passed" if failures == 0 else "Isometric Visual Lab failures: %d" % failures)
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _select_labelled_option(lab: Control, label_text: String, index: int) -> bool:
	var children: Array[Node] = lab.list.get_children()
	for i in children.size() - 1:
		if children[i] is Label and children[i].text == label_text and children[i + 1] is OptionButton:
			(children[i + 1] as OptionButton).item_selected.emit(index)
			return true
	return false
