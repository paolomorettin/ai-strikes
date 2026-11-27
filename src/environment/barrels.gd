class_name Barrels
extends Area3D

var barrel_positions: Array[Vector3]


func explode(_body: Node3D):
	for pos in barrel_positions:
		var explosion = Explosion.new(pos, 1.5 * Wheelchair.explosion_radius, Wheelchair.explosion_speed)
		get_parent().add_child(explosion)
	queue_free()


func _ready() -> void:
	body_entered.connect(explode)
	barrel_positions = [
		%Barrel_001.global_position,
		%Barrel_002.global_position,
		%Barrel_003.global_position,
		%Barrel_004.global_position
	]
