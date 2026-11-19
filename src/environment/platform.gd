@tool
class_name Platform
extends StaticBody3D

const DEPTH = 2.0

var collision_box: BoxShape3D
var mesh_box: BoxMesh

@export var color: Color = Color.DIM_GRAY:
	set(value):
		if is_node_ready():
			color = value
			mesh_box.material.albedo_color = color

@export var platform_size: Vector2:# = Vector2(1.0, 0.5):
	set(value):
		if is_node_ready():
			platform_size = value
			var size3d: Vector3 = Vector3(platform_size.x, platform_size.y, DEPTH)
			collision_box.size = size3d
			mesh_box.size = size3d
		

func _ready() -> void:
	collision_box = BoxShape3D.new()
	mesh_box = BoxMesh.new()
	mesh_box.material = StandardMaterial3D.new()
	
	var collision_shape = CollisionShape3D.new()
	add_child(collision_shape)
	collision_shape.shape = collision_box
	
	var mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	mesh_instance.mesh = mesh_box
	
	
