class_name SlingshotBoy
extends CharacterBody3D

@export var speed := 8.0
@export var accel := 60.0
@export var air_accel := 10.0
@export var gravity := 9.8 * 3.0
@export var jump := 8.0
@export var stretch_look := false
@export var turn_follow := 8
@export var bob_height := 0.12
@export var bob_rate := 10.0
@export var swing := 0.4

var _pitch := deg_to_rad(-15.0)
var _turn := 0.0
var _bob := 0.0
var _bob_amount := 0.0
var _model_rest_y := 0.0
var _swing_amount := 0.0
var _left_hand_rest := Vector3.ZERO
var _right_hand_rest := Vector3.ZERO

@onready var _pivot: Node3D = $CameraPivot
@onready var _pitch_pivot: Node3D = $CameraPivot/Pitch
@onready var _model: Node3D = $SlingshotBody

@onready var _left_hand: Marker3D = $SlingshotBody/Skeleton/LeftHandTarget
@onready var _right_hand: Marker3D = $SlingshotBody/Skeleton/RightHandTarget

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$CameraPivot/Pitch/SpringArm3D.add_excluded_object(get_rid())
	_model_rest_y = _model.position.y
	
	_left_hand_rest = _left_hand.position
	_right_hand_rest = _right_hand.position


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
	var move := Vector3(velocity.x, 0.0, velocity.z)
	var target_yaw := _model.rotation.y
	if stretch_look:
		target_yaw = camera_yaw
	elif move.length_squared() > 0.25:
		target_yaw = atan2(move.x, move.z)
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, 1.0 - exp(-turn_follow * delta))
	_bob_body(delta, move)

func _bob_body(delta: float, move: Vector3) -> void:
	var moving := is_on_floor() and move.length_squared() > 0.25
	var target := 0.0
	if moving:
		target = bob_height * clampf(move.length() / speed, 0.35, 1.0)
		_bob += delta * bob_rate * clampf(move.length() / speed, 0.35, 1.5)
	_bob_amount = lerpf(_bob_amount, target, 1.0 - exp(-8.0 * delta))
	_model.position.y = _model_rest_y + abs(sin(_bob)) * _bob_amount
	
	var swing_target := swing if moving else 0.0
	_swing_amount = lerpf(_swing_amount, swing_target, 1.0 - exp(-8.0 * delta))
	var along := sin(_bob) * _swing_amount
	_left_hand.position = _left_hand_rest + Vector3(0.0, 0.0, along)
	_right_hand.position = _right_hand_rest + Vector3(0.0, 0.0, -along)
