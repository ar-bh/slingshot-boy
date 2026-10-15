@tool
extends Node3D

@export_group("Tube")
@export var thickness := -0.14
@export var bend := 0.12

var _thickness_applied := -1.0

@onready var tube := $LeftLeg/Tube
@onready var tube_right := $RightLeg/Tube

var constant_pos: Vector3
var constant_pos_ref: Vector3
var wish_pos: Vector3

var distance_threshold := 1.0
var _tween: Tween
var _tween_right: Tween

func _ready() -> void:
	for leg in [$LeftLeg, $RightLeg]:
		#region tube
		var leg_tube := leg.get_node(^"Tube") as CSGPolygon3D
		leg_tube.mode = CSGPolygon3D.MODE_PATH
		leg_tube.path_node = leg_tube.get_path_to(leg.get_node(^"Path3D"))
		leg_tube.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH_FOLLOW
		leg_tube.path_interval = 0.04
		leg_tube.path_simplify_angle = 0.0
		leg_tube.path_rotation_accurate = true
		leg_tube.path_local = true
		leg_tube.smooth_faces = true
		#endregion
		if Engine.is_editor_hint():
			continue
		leg.get_node(^"WishFoot").top_level = true
	_apply_thickness()


func _process(_delta: float) -> void:
	_apply_thickness()
	_leg($LeftLeg, -1.0, _tween)
	_leg($RightLeg, 1.0, _tween_right)


func _leg(leg: Node, side: float, tween: Tween) -> void:
	var knee := Vector3(leg.get_node(^"Middle").position) + Vector3(side * bend, 0.0, 0.0)
	_set_curve(leg, Vector3(leg.get_node(^"Beginning").position), knee, Vector3(leg.get_node(^"End").position))
	
	if Engine.is_editor_hint():
		return
	
	var constant_foot: Node3D = leg.get_node(^"ConstantFoot")
	var wish_foot: Node3D = leg.get_node(^"WishFoot")
	var end: Node3D = leg.get_node(^"End")
	constant_pos = constant_foot.global_position
	wish_pos = wish_foot.global_position
	
	end.global_position = wish_foot.global_position
	
	if constant_pos.distance_to(wish_foot.global_position) >= distance_threshold:
		if tween == null or not tween.is_running():
			var from: Vector3 = wish_foot.global_position
			tween = create_tween()
			tween.tween_method(func(t: float) -> void:
				wish_foot.global_position = from.lerp(constant_foot.global_position, t)
				, 0.252, 1.0, 0.2)
	if leg == $LeftLeg:
		_tween = tween
	else:
		_tween_right = tween


#region tube
func _apply_thickness() -> void:
	if is_equal_approx(_thickness_applied, thickness):
		return
	_thickness_applied = thickness
	var ring := PackedVector2Array()
	for i in 10:
		var angle := TAU * float(i) / 10.0
		ring.append(Vector2(cos(angle), sin(angle)) * thickness)
	tube.polygon = ring
	tube_right.polygon = ring

func _set_curve(leg: Node, hip: Vector3, knee: Vector3, foot: Vector3) -> void:
	var path := leg.get_node(^"Path3D") as Path3D
	var curve := path.curve
	var control := 2.0 * knee - 0.5 * (hip + foot)
	var steps := 12
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
#endregion
