@tool
extends Skeleton3D

func _ready() -> void:
	_build_arm("Left", -1.0)
	_build_arm("Right", 1.0)

func _build_arm(side: String, sign: float) -> void:
	var shoulder_name := side + "Shoulder"
	if find_bone(shoulder_name) != -1:
		return
	var shoulder := add_bone(shoulder_name)
	var elbow := add_bone(side + "Elbow")
	var hand := add_bone(side + "Hand")
	set_bone_parent(elbow, shoulder)
	set_bone_parent(hand, elbow)
	_place(shoulder, Vector3(0.5 * sign, -0.05, 0.0))
	_place(elbow, Vector3(0.34 * sign, -0.1, 0.08))
	_place(hand, Vector3(0.16 * sign, -0.2, -0.02))

func _place(index: int, pos: Vector3) -> void:
	set_bone_rest(index, Transform3D(Basis.IDENTITY, pos))
	set_bone_pose_position(index, pos)
	set_bone_pose_rotation(index, Quaternion.IDENTITY)
	set_bone_pose_scale(index, Vector3.ONE)
