@tool
extends Node3D

@export var thickness := -0.14

var _thickness_applied := 999.0

@onready var skeleton: Skeleton3D = $".."
@onready var left_path: Path3D = $LeftPath
@onready var right_path: Path3D = $RightPath
@onready var left_tube: CSGPolygon3D = $LeftTube
@onready var right_tube: CSGPolygon3D = $RightTube

func _ready() -> void:
	if not skeleton.skeleton_updated.is_connected(_on_skeleton_updated):
		skeleton.skeleton_updated.connect(_on_skeleton_updated)

func _on_skeleton_updated() -> void:
	_apply_thickness()
	_set_curve(left_path, "LeftShoulder", "LeftElbow", "LeftHand")
	_set_curve(right_path, "RightShoulder", "RightElbow", "RightHand")

func _set_curve(path: Path3D, shoulder_name: String, elbow_name: String, hand_name: String) -> void:
	var shoulder := _bone_pos(shoulder_name)
	var elbow := _bone_pos(elbow_name)
	var hand := _bone_pos(hand_name)
	var control := 2.0 * elbow - 0.5 * (shoulder + hand)
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
		var point := shoulder.lerp(elbow, t * 2.0)
		if t >= 0.5:
			point = elbow.lerp(hand, (t - 0.5) * 2.0)
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
	
