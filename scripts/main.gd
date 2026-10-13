extends Node3D

const WorldGeneratorScript = preload("res://scripts/world_generator.gd")
const OrbitCameraScript = preload("res://scripts/orbit_camera.gd")

var _world: WorldGenerator
var _camera_rig: OrbitCamera
var _seed_input: SpinBox
var _status_label: Label
var _height_slider: HSlider
var _resolution_slider: HSlider
var _preset_name: LineEdit
var _preset_list: OptionButton
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_make_environment()
	_make_world()
	_make_camera()
	_make_ui()
	_load_settings()
	_make_preset_controls()
	_generate_world(int(_seed_input.value))


func _make_environment() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.12, 0.22, 0.38)
	sky_material.sky_horizon_color = Color(0.72, 0.79, 0.83)
	sky_material.ground_bottom_color = Color(0.12, 0.14, 0.16)
	sky_material.ground_horizon_color = Color(0.42, 0.48, 0.49)
	sky.sky_material = sky_material
	settings.sky = sky
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = settings
	add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)


func _make_world() -> void:
	_world = WorldGeneratorScript.new()
	_world.name = "GeneratedTerrain"
	add_child(_world)

	var water := MeshInstance3D.new()
	water.name = "WaterPlane"
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(120.0, 120.0)
	water.mesh = water_mesh
	water.position.y = -1.7
	var water_material := StandardMaterial3D.new()
	water_material.albedo_color = Color(0.12, 0.34, 0.48, 0.82)
	water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_material.roughness = 0.28
	water_material.metallic = 0.12
	water_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	water.material_override = water_material
	add_child(water)


func _make_camera() -> void:
	_camera_rig = OrbitCameraScript.new()
	_camera_rig.name = "OrbitCamera"
	add_child(_camera_rig)


func _make_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Interface"
	add_child(layer)

	var panel := PanelContainer.new()
	panel.position = Vector2(24, 24)
	panel.custom_minimum_size = Vector2(300, 0)
	layer.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)

	var title := Label.new()
	title.text = "PIXEL  /  WORLD LAB"
	title.add_theme_font_size_override("font_size", 21)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "procedural terrain prototype"
	subtitle.add_theme_color_override("font_color", Color(0.65, 0.72, 0.78))
	layout.add_child(subtitle)

	var seed_row := HBoxContainer.new()
	layout.add_child(seed_row)

	var seed_label := Label.new()
	seed_label.text = "seed"
	seed_row.add_child(seed_label)

	_seed_input = SpinBox.new()
	_seed_input.min_value = 0
	_seed_input.max_value = 999999999
	_seed_input.value = 12345
	_seed_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_row.add_child(_seed_input)

	var height_label := Label.new()
	height_label.text = "terrain height"
	layout.add_child(height_label)
	_height_slider = HSlider.new()
	_height_slider.min_value = 6
	_height_slider.max_value = 36
	_height_slider.step = 1
	_height_slider.value = 20
	_height_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(_height_slider)

	var detail_label := Label.new()
	detail_label.text = "terrain detail"
	layout.add_child(detail_label)
	_resolution_slider = HSlider.new()
	_resolution_slider.min_value = 64
	_resolution_slider.max_value = 192
	_resolution_slider.step = 16
	_resolution_slider.value = 160
	_resolution_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(_resolution_slider)

	var generate_button := Button.new()
	generate_button.text = "generate world"
	generate_button.pressed.connect(_generate_from_input)
	layout.add_child(generate_button)

	var copy_seed_button := Button.new()
	copy_seed_button.text = "copy seed"
	copy_seed_button.pressed.connect(_copy_seed)
	layout.add_child(copy_seed_button)

	var reset_view_button := Button.new()
	reset_view_button.text = "reset camera"
	reset_view_button.pressed.connect(_camera_rig.reset_view)
	layout.add_child(reset_view_button)

	var random_button := Button.new()
	random_button.text = "random seed"
	random_button.pressed.connect(_generate_new_world)
	layout.add_child(random_button)

	_status_label = Label.new()
	_status_label.text = "ready"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_status_label)

	var preset_title := Label.new()
	preset_title.text = "world presets"
	layout.add_child(preset_title)

	_preset_name = LineEdit.new()
	_preset_name.placeholder_text = "name this world"
	_preset_name.max_length = 32
	layout.add_child(_preset_name)

	_preset_list = OptionButton.new()
	_preset_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(_preset_list)

	var save_preset_button := Button.new()
	save_preset_button.text = "save preset"
	save_preset_button.pressed.connect(_save_preset)
	layout.add_child(save_preset_button)

	var load_preset_button := Button.new()
	load_preset_button.text = "load selected preset"
	load_preset_button.pressed.connect(_load_selected_preset)
	layout.add_child(load_preset_button)

	var delete_preset_button := Button.new()
	delete_preset_button.text = "delete selected preset"
	delete_preset_button.pressed.connect(_delete_selected_preset)
	layout.add_child(delete_preset_button)

	var controls := Label.new()
	controls.text = "right mouse: orbit\nmouse wheel: zoom\nesc: release mouse"
	controls.add_theme_color_override("font_color", Color(0.7, 0.76, 0.82))
	layout.add_child(controls)


func _generate_from_input() -> void:
	_generate_world(int(_seed_input.value))


func _generate_new_world() -> void:
	var next_seed := _rng.randi_range(0, 999999999)
	_seed_input.value = next_seed
	_generate_world(next_seed)


func _generate_world(seed_value: int) -> void:
	_status_label.text = "generating terrain..."
	_world.height_scale = _height_slider.value
	_world.resolution = int(_resolution_slider.value)
	_world.generate_world(seed_value)
	_save_settings(seed_value)
	_status_label.text = "world ready  /  seed %d  /  %d x %d vertices" % [
		seed_value, _world.resolution, _world.resolution
	]


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://pixel.cfg") != OK:
		return
	_seed_input.value = int(config.get_value("world", "seed", 12345))
	_height_slider.value = float(config.get_value("world", "height_scale", 20.0))
	_resolution_slider.value = float(config.get_value("world", "resolution", 160))


func _save_settings(seed_value: int) -> void:
	var config := ConfigFile.new()
	config.set_value("world", "seed", seed_value)
	config.set_value("world", "height_scale", _height_slider.value)
	config.set_value("world", "resolution", int(_resolution_slider.value))
	var result := config.save("user://pixel.cfg")
	if result != OK:
		push_warning("could not save world settings")


func _copy_seed() -> void:
	var seed_text := str(int(_seed_input.value))
	DisplayServer.clipboard_set(seed_text)
	_status_label.text = "copied seed %s" % seed_text


func _make_preset_controls() -> void:
	_refresh_presets()


func _refresh_presets(select_name: String = "") -> void:
	_preset_list.clear()
	var config := ConfigFile.new()
	if config.load("user://world_presets.cfg") == OK:
		var sections := config.get_sections()
		sections.sort()
		for preset_name in sections:
			_preset_list.add_item(preset_name)
			if preset_name == select_name:
				_preset_list.select(_preset_list.item_count - 1)


func _save_preset() -> void:
	var preset_name := _preset_name.text.strip_edges()
	if preset_name.is_empty():
		_status_label.text = "give the preset a name first"
		return
	preset_name = preset_name.replace("/", "-").replace("\\", "-")
	var config := ConfigFile.new()
	var load_result := config.load("user://world_presets.cfg")
	if load_result != OK and load_result != ERR_FILE_NOT_FOUND:
		_status_label.text = "couldn't read saved presets"
		return
	config.set_value(preset_name, "seed", int(_seed_input.value))
	config.set_value(preset_name, "height_scale", _height_slider.value)
	config.set_value(preset_name, "resolution", int(_resolution_slider.value))
	var save_result := config.save("user://world_presets.cfg")
	if save_result != OK:
		_status_label.text = "couldn't save preset"
		return
	_refresh_presets(preset_name)
	_status_label.text = "saved preset: %s" % preset_name


func _load_selected_preset() -> void:
	var selected := _preset_list.get_selected_id()
	if selected < 0:
		_status_label.text = "pick a preset first"
		return
	var preset_name := _preset_list.get_item_text(_preset_list.selected)
	var config := ConfigFile.new()
	if config.load("user://world_presets.cfg") != OK:
		_status_label.text = "couldn't open saved presets"
		return
	_seed_input.value = int(config.get_value(preset_name, "seed", 12345))
	_height_slider.value = float(config.get_value(preset_name, "height_scale", 20.0))
	_resolution_slider.value = float(config.get_value(preset_name, "resolution", 160))
	_generate_world(int(_seed_input.value))


func _delete_selected_preset() -> void:
	if _preset_list.selected < 0:
		_status_label.text = "pick a preset first"
		return
	var preset_name := _preset_list.get_item_text(_preset_list.selected)
	var config := ConfigFile.new()
	if config.load("user://world_presets.cfg") != OK:
		_status_label.text = "couldn't open saved presets"
		return
	config.erase_section(preset_name)
	if config.save("user://world_presets.cfg") != OK:
		_status_label.text = "couldn't delete preset"
		return
	_refresh_presets()
	_status_label.text = "deleted preset: %s" % preset_name
