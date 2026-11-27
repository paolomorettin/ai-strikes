class_name Explosion
extends Node3D

var explosion_point: Vector3
var explosion_radius: float # m
var explosion_speed: float # m/s

func _init(exp_point: Vector3, exp_radius: float, exp_speed: float) -> void:
	explosion_point = exp_point
	explosion_radius = exp_radius
	explosion_speed = exp_speed

func _ready():
	
	global_position = explosion_point
	var parent_node: Node = get_parent()
	
	# particle
	var explosion_particle: CPUParticles3D = preload("res://particles/explosion_particle.tscn").instantiate()
	parent_node.add_child(explosion_particle)
	explosion_particle.global_position = explosion_point
	explosion_particle.finished.connect(explosion_particle.queue_free)
	
	# light
	var explosion_light := OmniLight3D.new()
	add_child(explosion_light)
	explosion_light.light_color = Color.ORANGE
	explosion_light.omni_range = 0.0
	
	# deadly blast
	var blast_area := Area3D.new()
	var blast_collision := CollisionShape3D.new()
	var blast_shape := SphereShape3D.new()
	add_child(blast_area)
	blast_area.add_child(blast_collision)
	blast_collision.shape = blast_shape
	blast_area.collision_layer = 0
	blast_area.collision_mask = 4
	blast_area.body_entered.connect(
		func (body):
			if body is Wheelchair and body != self:
				(body as Wheelchair).die()
	)
	blast_shape.radius = 0.1
	
	# BOOM!
	explosion_particle.emitting = true
	var blast_tween: Tween = get_tree().create_tween()
	blast_tween.tween_property(blast_shape, "radius", explosion_radius, 1.0 / explosion_speed)
	blast_tween.tween_callback(blast_area.queue_free)
	var light_tween: Tween = get_tree().create_tween()
	light_tween.tween_property(explosion_light, "omni_range", explosion_radius, 1.0 / explosion_speed)
	light_tween.parallel()
	light_tween.tween_property(explosion_light, "light_energy", 10.0, explosion_particle.lifetime)
	light_tween.tween_property(explosion_light, "light_energy", 0.0, 0.2)
	light_tween.tween_callback(queue_free)
	
	
