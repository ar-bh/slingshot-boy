class_name SlingshotBoy
extends CharacterBody3D

@export var speed := 8.0
@export var accel := 60.0
@export var air_accel := 10.0
@export var gravity := 9.8 * 3.0
@export var jump := 8.0
@export var turn_degrees := 25.0
@export var turn_follow := 8

var _pitch := deg_to_rad(-15.0)
var _turn := 0.0

@onready var _pivot: Node3D = $CameraPivot
@onready var _pitch_pivot: Node3D = $CameraPivot/Pitch
@onready var _model: Node3D = $SlingshotBody


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$CameraPivot/Pitch/SpringArm3D.add_excluded_object(get_rid())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_pivot.rotate_y(-event.relative.x * 0.0025)
		_pitch = clampf(_pitch - event.relative.y * 0.0025, deg_to_rad(-90.0), deg_to_rad(90.0))
		_pitch_pivot.rotation.x = _pitch
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var wish := _pivot.global_basis * Vector3(input.x, 0.0, input.y)
	wish.y = 0.0
	if wish.length_squared() > 0.0001:
		wish = wish.normalized()
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump
	var rate := accel if is_on_floor() else air_accel
	var horiz := Vector3(velocity.x, 0.0, velocity.z).move_toward(wish * speed, rate * delta)
	velocity.x = horiz.x
	velocity.z = horiz.z
	move_and_slide()
	
	var forward := -_pivot.global_basis.z
	forward.y = 0.0
	var camera_yaw := atan2(forward.x, forward.z)
	var side_dir := _pivot.global_basis.x
	side_dir.y = 0.0
	var side := 0.0
	if side_dir.length_squared() > 0.0001:
		side = Vector3(velocity.x, 0.0, velocity.z).dot(side_dir.normalized()) / speed
	var target_turn := clampf(-side, -1.0, 1.0) * deg_to_rad(turn_degrees)
	_turn = lerpf(_turn, target_turn, 1.0 - exp(-turn_follow * delta))
	_model.rotation.y = camera_yaw + _turn
