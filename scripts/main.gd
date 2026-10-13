extends Node3D

const WorldGeneratorScript = preload("res://scripts/world_generator.gd")
const OrbitCameraScript = preload("res://scripts/orbit_camera.gd")

var _world: WorldGenerator
var _seed_input: SpinBox
var _status_label: Label
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_make_environment()
	_make_world()
	_make_camera()
	_make_ui()
	_generate_new_world()


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
	var camera_rig: OrbitCamera = OrbitCameraScript.new()
	camera_rig.name = "OrbitCamera"
	add_child(camera_rig)


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

	var generate_button := Button.new()
	generate_button.text = "generate world"
	generate_button.pressed.connect(_generate_from_input)
	layout.add_child(generate_button)

	var random_button := Button.new()
	random_button.text = "random seed"
	random_button.pressed.connect(_generate_new_world)
	layout.add_child(random_button)

	_status_label = Label.new()
	_status_label.text = "ready"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_status_label)

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
	_world.generate_world(seed_value)
	_status_label.text = "world ready  /  seed %d  /  %d x %d vertices" % [
		seed_value, _world.resolution, _world.resolution
	]
