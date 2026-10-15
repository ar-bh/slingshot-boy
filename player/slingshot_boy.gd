class_name SlingshotBoy
extends CharacterBody3D

const SPEED := 5.0
const ACCEL := 60.0
const AIR_ACCEL := 10.0
const GRAVITY := 9.8 * 3.0
const JUMP := 8.0

var _pitch := deg_to_rad(-15.0)

@onready var _pivot: Node3D = $CameraPivot
@onready var _pitch_pivot: Node3D = $CameraPivot/Pitch
@onready var _model: Node3D = $SlingshotMesh


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
		velocity.y -= GRAVITY * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP
	var rate := ACCEL if is_on_floor() else AIR_ACCEL
	var horiz := Vector3(velocity.x, 0.0, velocity.z).move_toward(wish * SPEED, rate * delta)
	velocity.x = horiz.x
	velocity.z = horiz.z
	move_and_slide()
	var forward := -_pivot.global_basis.z
	forward.y = 0.0
	_model.rotation.y = atan2(forward.x, forward.z)
