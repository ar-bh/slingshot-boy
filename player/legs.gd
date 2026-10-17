@tool
extends Node3D

@export var thickness := -0.14
@export var shoe_lift := 0.2

var _thickness_applied := 999.0

@onready var skeleton: Skeleton3D = $".."
@onready var left_path: Path3D = $LeftPath
@onready var right_path: Path3D = $RightPath
@onready var left_tube: CSGPolygon3D = $LeftTube
@onready var right_tube: CSGPolygon3D = $RightTube

func _process(_delta: float) -> void:
	_apply_thickness()
	_set_curve(left_path, "LeftHip", "LeftKnee", "LeftFoot")
	_set_curve(right_path, "RightHip", "RightKnee", "RightFoot")

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

func _set_curve(path: Path3D, hip_name: String, knee_name: String, foot_name: String) -> void:
	var hip := _bone_pos(hip_name) + Vector3(0, 0.4, 0)
	var knee := _bone_pos(knee_name)
	var foot := _bone_pos(foot_name) + Vector3(0, 0.15, 0)
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

func _bone_pos(bone_name: String) -> Vector3:
	return skeleton.get_bone_global_pose(skeleton.find_bone(bone_name)).origin
