extends Node3D
class_name OrbitCamera

@export var distance: float = 105.0
@export var min_distance: float = 18.0
@export var max_distance: float = 210.0
@export var orbit_sensitivity: float = 0.008
@export var zoom_step: float = 8.0

var _dragging := false
var _yaw := 0.65
var _pitch := -0.48
var _camera: Camera3D


func _ready() -> void:
	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.current = true
	add_child(_camera)
	_update_camera()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = event.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _dragging else Input.MOUSE_MODE_VISIBLE
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = max(min_distance, distance - zoom_step)
			_update_camera()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = min(max_distance, distance + zoom_step)
			_update_camera()
	elif event is InputEventMouseMotion and _dragging:
		_yaw -= event.relative.x * orbit_sensitivity
		_pitch = clamp(_pitch - event.relative.y * orbit_sensitivity, -1.35, -0.08)
		_update_camera()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_dragging = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _update_camera() -> void:
	if _camera == null:
		return
	var direction := Vector3(
		cos(_pitch) * sin(_yaw),
		-sin(_pitch),
		cos(_pitch) * cos(_yaw)
	)
	_camera.position = direction * distance
	_camera.look_at(Vector3.ZERO, Vector3.UP)
