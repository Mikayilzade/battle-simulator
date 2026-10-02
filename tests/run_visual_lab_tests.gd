extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var catalog := VisualLabCatalog.load_catalog()
	_check(catalog.variants.size() == 34, "34 authored visual resources load")
	_check(catalog.validation_errors().is_empty(), "variant catalog validates: %s" % catalog.validation_errors())
	var main := load("res://ui/main/Main.tscn").instantiate() as Control
	root.add_child(main)
	await process_frame
	_check(main.screen.scene_file_path == "res://ui/setup/Setup.tscn", "main opens setup")
	var setup_config: Dictionary = main.screen.build_config()
	main.screen.lab_requested.emit(setup_config)
	await process_frame
	var lab: Control = main.screen
	_check(lab.scene_file_path == "res://ui/visual_lab/VisualLab.tscn", "setup opens visual lab")
	_check(lab.tabs.get_tab_count() == 5, "five browsable areas exist")
	_check(lab.preview.size.x >= 600 and lab.preview.size.y >= 400, "preview occupies main stage")
	_check(lab.selection.terrain_ids[&"plain"] == &"TERRAIN-PLAIN-2D-01" and lab.selection.unit_ids[&"guard"] == &"UNIT-GUARD-2D-01", "initial combined sample uses a coherent 2D set")
	_check(lab.select_variant(&"FIELD-3D-01"), "field variant can be selected")
	var first_card: PanelContainer = lab.tabs.get_child(0).get_child(0).get_child(0)
	var card_actions: HBoxContainer = first_card.get_child(0).get_child(3)
	(card_actions.get_child(0) as Button).pressed.emit()
	_check(lab.selection.field_id == &"FIELD-25D-01", "variant card changes preview selection")
	_check(lab.select_variant(&"FIELD-3D-01"), "field can switch back to faux-3D")
	_check(lab.select_variant(&"TERRAIN-FOREST-25D-01"), "terrain variant can be selected")
	_check(lab.select_variant(&"UNIT-ARCHER-3D-01"), "unit variant can be selected")
	_check(lab.selection.field_id == &"FIELD-3D-01" and lab.selection.terrain_ids[&"forest"] == &"TERRAIN-FOREST-25D-01" and lab.selection.unit_ids[&"archer"] == &"UNIT-ARCHER-3D-01", "combined preview mixes independent categories")
	_check(lab.mark_variant(&"FIELD-2D-01", VisualLabSelection.FAVORITE), "favorite variant")
	_check(lab.mark_variant(&"UNIT-GUARD-2D-01", VisualLabSelection.ARCHIVE), "archive variant")
	_check(lab.selection.status_of(&"FIELD-2D-01") == VisualLabSelection.FAVORITE and lab.selection.status_of(&"UNIT-GUARD-2D-01") == VisualLabSelection.ARCHIVE, "statuses remain separate from preview")
	_check(lab.select_variant(&"UNIT-GUARD-2D-01"), "archived variant remains selectable")
	_check(lab.catalog.get_variant(&"UNIT-GUARD-2D-01") != null, "archived resource is retained")
	_check(lab.preview.selection == lab.selection and lab.preview.catalog == lab.catalog, "preview reads selected visual data")
	lab.exit_requested.emit(setup_config)
	await process_frame
	_check(main.screen.scene_file_path == "res://ui/setup/Setup.tscn", "return restores setup")
	_check(main.screen.build_config() == setup_config, "setup selections preserved")
	main.screen.lab_requested.emit(setup_config)
	await process_frame
	_check(main.screen.selection.field_id == &"FIELD-3D-01" and main.screen.selection.status_of(&"FIELD-2D-01") == VisualLabSelection.FAVORITE, "lab choices survive reentry during session")
	_check(main.screen.return_config == setup_config, "lab does not mutate battle setup")
	print("Visual Lab tests passed" if failures == 0 else "Visual Lab failures: %d" % failures)
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
