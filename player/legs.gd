@tool
extends Node3D

@export_group("Tube Legs")
@export var thickness := -0.14
@export var shoe_lift := 0.2

@export_group("Proc Anim")
@export var distance_threshold := 0.55
@export var step_time := 0.12
@export var step_height := 0.45
@export var foot_spring := 10.0
@export var foot_damping := 1
@export var foot_gravity := 0


var _left_tween: Tween
var _right_tween: Tween
var _step_left := true

var _airborne := false
var _left_foot_vel := Vector3.ZERO
var _right_foot_vel := Vector3.ZERO

var _thickness_applied := 999.0

@onready var skeleton: Skeleton3D = $".."
@onready var left_path: Path3D = $LeftPath
@onready var right_path: Path3D = $RightPath
@onready var left_tube: CSGPolygon3D = $LeftTube
@onready var right_tube: CSGPolygon3D = $RightTube

@onready var left_constant: Marker3D = %LeftConstant
@onready var right_constant: Marker3D = %RightConstant
@onready var left_foot_target: Marker3D = %LeftFootTarget
@onready var right_foot_target: Marker3D = %RightFootTarget
var left_constant_pos: Vector3
var right_constant_pos: Vector3

var _left_shoe_pos := Vector3(0.07975447, 0.22957239, 0.04510027)
var _right_shoe_pos := Vector3(-0.0655607, 0.22957239, 0.04510027)

func _ready() -> void:
	if not skeleton.skeleton_updated.is_connected(_on_skeleton_updated):
		skeleton.skeleton_updated.connect(_on_skeleton_updated)
	
	if Engine.is_editor_hint():
		return
	
	left_foot_target.top_level = true
	right_foot_target.top_level = true

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	left_constant_pos = left_constant.global_position
	right_constant_pos = right_constant.global_position

	var body := _character()
	var airborne := body != null and not body.is_on_floor()
	if airborne:
		if not _airborne:
			_begin_flop(body)
		_left_foot_vel = _flop_foot(left_foot_target, left_constant, _left_foot_vel, delta)
		_right_foot_vel = _flop_foot(right_foot_target, right_constant, _right_foot_vel, delta)
		_airborne = true
		return
	if _airborne:
		_left_foot_vel = Vector3.ZERO
		_right_foot_vel = Vector3.ZERO
	_airborne = false
	
	var left_busy := _left_tween != null and _left_tween.is_running()
	var right_busy := _right_tween != null and _right_tween.is_running()
	if left_busy or right_busy:
		return
	
	var left_due := left_constant.global_position.distance_to(left_foot_target.global_position) > distance_threshold
	var right_due := right_constant.global_position.distance_to(right_foot_target.global_position) > distance_threshold
	
	if _step_left and left_due:
		_left_tween = _begin_step(left_foot_target, left_constant, "LeftHip")
		_step_left = false
	elif right_due:
		_right_tween = _begin_step(right_foot_target, right_constant, "RightHip")
		_step_left = true
	elif left_due:
		_left_tween = _begin_step(left_foot_target, left_constant, "LeftHip")
		_step_left = false

func _on_skeleton_updated() -> void:
	#_stretch_leg("LeftHip", "LeftKnee", "LeftFoot", left_foot_target)
	#_stretch_leg("RightHip", "RightKnee", "RightFoot", right_foot_target)
	_apply_thickness()
	_set_curve(left_path, "LeftHip", "LeftKnee", $"../LeftShoe/MeshInstance3D")
	_set_curve(right_path, "RightHip", "RightKnee", $"../RightShoe/MeshInstance3D")
	
func _set_curve(path: Path3D, hip_name: String, knee_name: String, shoe: Node3D) -> void:
	var hip := _bone_pos(hip_name) + Vector3(0.0, 0.4, 0.0)
	var knee := _bone_pos(knee_name)
	var foot := skeleton.to_local(shoe.global_position) + Vector3(0.0, 0.12, 0.0)
	var control := 2.0 * knee - 0.5 * (hip + foot)
	var curve := path.curve
	var steps := 12
	if curve == null:
		return
	if curve.point_count != steps:
		curve.clear_points()
		for _i in steps:
			curve.add_point(Vector3.ZERO)
	for i in steps:
		var t := float(i) / float(steps - 1)
		var u := 1.0 - t
		var point := u * u * hip + 2.0 * u * t * control + t * t * foot
		curve.set_point_position(i, point)
		curve.set_point_in(i, Vector3.ZERO)
		curve.set_point_out(i, Vector3.ZERO)

func _apply_thickness() -> void:
	if is_equal_approx(_thickness_applied, thickness):
		return
	_thickness_applied = thickness
	var ring := PackedVector2Array()
	for i in 10:
		var angle := TAU * float(i) / 10.0
		ring.append(Vector2(cos(angle), sin(angle)) * thickness)
	left_tube.polygon = ring
	right_tube.polygon = ring

func _bone_pos(bone_name: String) -> Vector3:
	return skeleton.get_bone_global_pose(skeleton.find_bone(bone_name)).origin

func _character() -> CharacterBody3D:
	var node: Node = self
	while node != null:
		if node is CharacterBody3D:
			return node
		node = node.get_parent()
	return null

func _release_feet() -> void:
	if _left_tween != null:
		_left_tween.kill()
	if _right_tween != null:
		_right_tween.kill()
	left_foot_target.global_position = left_constant.global_position
	right_foot_target.global_position = right_constant.global_position

func _begin_step(target: Marker3D, constant: Marker3D, hip_name: String) -> Tween:
	var from := target.global_position
	var travel := from.distance_to(_step_aim(constant))
	var lift := minf(step_height * travel / distance_threshold, step_height * 1.25)
	var duration := clampf(travel / 6.0, step_time, 0.24)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(t: float) -> void:
		var aim := _step_aim(constant)
		var pos := from.lerp(aim, t)
		var tuck := sin(t * PI)
		var hip := skeleton.to_global(_bone_pos(hip_name))
		pos = pos.lerp(Vector3(hip.x, pos.y, hip.z), tuck * 0.35)
		pos.y += tuck * lift
		target.global_position = pos
	, 0.0, 1.0, duration)
	return tween

func _step_aim(constant: Marker3D) -> Vector3:
	return constant.global_position + _move_dir() * distance_threshold

func _move_dir() -> Vector3:
	var body := _character()
	if body == null:
		return Vector3.ZERO
	var dir := body.velocity
	dir.y = 0.0
	if dir.length_squared() < 0.04:
		return Vector3.ZERO
	return dir.normalized()

func _stretch_leg(hip_name: String, knee_name: String, foot_name: String, target: Node3D) -> void:
	var hip_i := skeleton.find_bone(hip_name)
	var knee_i := skeleton.find_bone(knee_name)
	var straight := skeleton.get_bone_rest(knee_i).origin.length() + skeleton.get_bone_rest(skeleton.find_bone(foot_name)).origin.length()
	if straight <= 0.001:
		return
	var goal := skeleton.to_local(target.global_position)
	var s := maxf(_bone_pos(hip_name).distance_to(goal) / straight, 1.0)
	var scale := Vector3(s, s, s)
	if skeleton.get_bone_pose_scale(hip_i).is_equal_approx(scale) and skeleton.get_bone_pose_scale(knee_i).is_equal_approx(Vector3.ONE):
		return
	skeleton.set_bone_pose_scale(hip_i, scale)
	skeleton.set_bone_pose_scale(knee_i, Vector3.ONE)

func _keep_shoe_size(hip_name: String, shoe: MeshInstance3D, rest_pos: Vector3) -> void:
	var s := skeleton.get_bone_pose_scale(skeleton.find_bone(hip_name)).x
	if s <= 0.001:
		return
	var inv := 1.0 / s
	shoe.position = rest_pos * inv
	shoe.scale = Vector3.ONE * inv

func _begin_flop(body: CharacterBody3D) -> void:
	if _left_tween != null:
		_left_tween.kill()
	if _right_tween != null:
		_right_tween.kill()
	var side := skeleton.global_basis.x
	side.y = 0.0
	if side.length_squared() > 0.0001:
		side = side.normalized()
	var carry := Vector3(body.velocity.x, 0.0, body.velocity.z)
	_left_foot_vel = carry - side * 1.5
	_right_foot_vel = carry + side * 1.5

func _flop_foot(target: Marker3D, constant: Marker3D, vel: Vector3, delta: float) -> Vector3:
	var pull := constant.global_position - target.global_position
	vel += pull * foot_spring * delta
	vel.y -= foot_gravity * delta
	vel *= exp(-foot_damping * delta)
	target.global_position += vel * delta
	if target.global_position.y < 0.0:
		target.global_position.y = 0.0
		vel.y = maxf(vel.y, 0.0)
	return vel
