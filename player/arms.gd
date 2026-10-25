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
	_stretch_arm("LeftShoulder", "LeftElbow", "LeftHand", $"../LeftHandTarget")
	_stretch_arm("RightShoulder", "RightElbow", "RightHand", $"../RightHandTarget")
	_keep_glove("LeftShoulder", $"../LeftGlove/MeshInstance3D")
	_keep_glove("RightShoulder", $"../RightGlove/MeshInstance3D")
	_apply_thickness()
	_set_curve(left_path, "LeftShoulder", "LeftElbow", "LeftHand")
	_set_curve(right_path, "RightShoulder", "RightElbow", "RightHand")

func _set_curve(path: Path3D, shoulder_name: String, elbow_name: String, hand_name: String) -> void:
	var shoulder := _bone_pos(shoulder_name)
	var elbow := _bone_pos(elbow_name)
	var hand := _bone_pos(hand_name)
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

func _stretch_arm(shoulder_name: String, elbow_name: String, hand_name: String, target: Node3D) -> void:
	if target == null:
		return
	var shoulder_i := skeleton.find_bone(shoulder_name)
	var elbow_i := skeleton.find_bone(elbow_name)
	var straight := skeleton.get_bone_rest(elbow_i).origin.length() + skeleton.get_bone_rest(skeleton.find_bone(hand_name)).origin.length()
	if straight <= 0.001:
		return
	var goal := skeleton.to_local(target.global_position)
	var s := maxf(_bone_pos(shoulder_name).distance_to(goal) / straight, 1.0)
	var scale := Vector3(s, s, s)
	if skeleton.get_bone_pose_scale(shoulder_i).is_equal_approx(scale) and skeleton.get_bone_pose_scale(elbow_i).is_equal_approx(Vector3.ONE):
		return
	skeleton.set_bone_pose_scale(shoulder_i, scale)
	skeleton.set_bone_pose_scale(elbow_i, Vector3.ONE)

func _keep_glove(shoulder_name: String, glove: MeshInstance3D) -> void:
	var s := skeleton.get_bone_pose_scale(skeleton.find_bone(shoulder_name)).x
	if s <= 0.001:
		return
	glove.scale = Vector3.ONE / s
