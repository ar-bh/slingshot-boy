@tool
extends Node3D

@export_group("Tube Legs")
@export var thickness := -0.14
@export var shoe_lift := 0.2

@export_group("Proc Anim")
@export var distance_threshold := 1.0

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


func _ready() -> void:
	if not skeleton.skeleton_updated.is_connected(_on_skeleton_updated):
		skeleton.skeleton_updated.connect(_on_skeleton_updated)
	
	if Engine.is_editor_hint():
		return
	
	left_foot_target.top_level = true
	right_foot_target.top_level = true

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	left_constant_pos = left_constant.global_position
	right_constant_pos = right_constant.global_position

	if left_constant.global_position.distance_to(left_foot_target.global_position) > distance_threshold:
		left_foot_target.global_position = left_constant.global_position
	if right_constant.global_position.distance_to(right_foot_target.global_position) > distance_threshold:
		right_foot_target.global_position = right_constant.global_position

#region tubes
func _on_skeleton_updated() -> void:
	_apply_thickness()
	_set_curve(left_path, "LeftHip", "LeftKnee", $"../LeftShoe/MeshInstance3D")
	_set_curve(right_path, "RightHip", "RightKnee", $"../RightShoe/MeshInstance3D")
	
func _set_curve(path: Path3D, hip_name: String, knee_name: String, shoe: Node3D) -> void:
	var hip := _bone_pos(hip_name)
	var knee := _bone_pos(knee_name)
	var foot := skeleton.to_local(shoe.global_position)
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
#endregion
