@tool
extends Node3D

@export var thickness := 0.3
@export var bend := 0.12
@export var bend_side := -1.0

var _thickness_applied := -1.0

@onready var tube := $Tube

func _ready() -> void:
	tube.mode = CSGPolygon3D.MODE_PATH
	tube.path_node = tube.get_path_to($Path3D)
	tube.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH_FOLLOW
	tube.path_interval = 0.04
	tube.path_simplify_angle = 0.0
	tube.path_rotation_accurate = true
	tube.smooth_faces = true
	_apply_thickness()

func _process(_delta: float) -> void:
	_apply_thickness()
	var knee: Vector3 = $Middle.global_position + global_basis.x * bend_side * bend
	_set_curve($Beginning.global_position, knee, $End.global_position)

func _apply_thickness() -> void:
	if is_equal_approx(_thickness_applied, thickness):
		return
	_thickness_applied = thickness
	var ring := PackedVector2Array()
	for i in 10:
		var angle := TAU * float(i) / 10.0
		ring.append(Vector2(cos(angle), sin(angle)) * thickness)
	tube.polygon = ring

func _set_curve(hip: Vector3, knee: Vector3, foot: Vector3) -> void:
	var path := $Path3D as Path3D
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
		curve.set_point_position(i, path.to_local(point))
		curve.set_point_in(i, Vector3.ZERO)
		curve.set_point_out(i, Vector3.ZERO)
