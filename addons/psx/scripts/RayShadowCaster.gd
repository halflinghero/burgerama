
class_name RayShadowCaster extends RayCast3D

static var shadow_quad : QuadMesh
static func _static_init() -> void:
	shadow_quad = QuadMesh.new()
	shadow_quad.orientation = PlaneMesh.FACE_Y
	shadow_quad.material = preload("uid://20ut3o26ngws")

@export var scale_with_distance : bool = false
@export var fade_with_distance : bool = false
@export var shadow_scale : float = 1.0
@export var shadow_scale_x : float = 1.0
@export var shadow_scale_z : float = 1.0
@export_range(0.0, 1.0, 0.01) var min_distance_scale : float = 0.35
@export var align_to_parent_yaw : bool = true

@export var margin : float = 0.025

var _material_override : Material
@export var material_override : Material = null :
	get: return _material_override
	set(value):
		if _material_override == value: return
		_material_override = value

		if mesh == null: return

		mesh.material_override = _material_override


var mesh : MeshInstance3D

func _init() -> void:
	mesh = MeshInstance3D.new()
	mesh.mesh = shadow_quad
	mesh.material_override = _material_override
	add_child(mesh)


func _process(delta: float) -> void:
	global_rotation = Vector3.ZERO

	mesh.visible = is_colliding()
	if not mesh.visible: return

	var collision_percent : float = global_position.distance_squared_to(get_collision_point()) / target_position.length_squared()
	var clamped_collision_percent := clamp(collision_percent, 0.0, 1.0)

	var ground_normal := get_collision_normal().normalized()
	mesh.global_position = get_collision_point() + ground_normal * margin
	mesh.global_basis.z = -ground_normal

	if align_to_parent_yaw and get_parent() is Node3D:
		var parent_yaw := (get_parent() as Node3D).global_rotation.y
		mesh.global_basis = Basis(ground_normal, parent_yaw) * mesh.global_basis

	mesh.transparency = collision_percent if fade_with_distance else 0.0
	var distance_scale := 1.0
	if scale_with_distance:
		distance_scale = max(min_distance_scale, 1.0 - clamped_collision_percent)

	mesh.scale = Vector3(
		shadow_scale * shadow_scale_x * distance_scale,
		1.0,
		shadow_scale * shadow_scale_z * distance_scale
	)
