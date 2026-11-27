class_name Exit
extends Node3D

static var strike_cost: int = 15
static var strike_duration: float = 15.0 # s

@onready var control_area: Area3D = %ControlArea

var despawn_point: Vector3
var is_despawning: bool = false
var strike_timer: Timer

##### GRAPHICS
var green_light_material: StandardMaterial3D = preload("res://materials/green_light_material.tres")
var no_light_material: StandardMaterial3D = preload("res://materials/no_light_material.tres")
var strike_light_material: StandardMaterial3D = preload("res://materials/strike_light_material.tres")

@onready var selection_overlay_meshes: Array[MeshInstance3D] = [%GateMesh]


func control_traffic(body: Node3D) -> void:
	if not (body is Wheelchair):
		return

	if strike_timer.is_stopped():
		if not is_despawning:
			serve(body)
		else:
			(body as Wheelchair).turn_around()
	
func serve(wheelchair: Wheelchair) -> void:
	is_despawning = true
	wheelchair.current_state = Wheelchair.State.OVERRIDE
	wheelchair.ttl_timer.stop()
	var horizontal_movement_duration = wheelchair.global_position.distance_to(global_position) / abs(wheelchair.velocity.x)
	var despawn_duration = -despawn_point.z / abs(wheelchair.velocity.x)
	var target_quaternion: Quaternion
	if wheelchair.global_position.x < global_position.x:
		target_quaternion = Quaternion(Vector3.UP, TAU / 4) * wheelchair.quaternion
	else:
		target_quaternion = Quaternion(Vector3.UP, -TAU / 4) * wheelchair.quaternion
	
	var tween = get_tree().create_tween()
	# x-movement to exit
	tween.tween_property(wheelchair, "global_position:x", global_position.x, horizontal_movement_duration)
	# rotation towards exit
	tween.tween_property(wheelchair, "quaternion", target_quaternion, wheelchair.turn_around_time / 2.0)
	# z-movement to exit
	tween.tween_property(wheelchair, "global_position:z", despawn_point.z, despawn_duration)
	tween.tween_callback(
		func (): 
			if is_instance_valid(wheelchair):
				wheelchair.queue_free() 
			is_despawning = false
	)
	
func can_strike() -> bool:
	return strike_timer.is_stopped()
	
func strike() -> void:
	strike_timer.start()
	_set_lights()
	

func _ready() -> void:
	despawn_point = Vector3(global_position.x, global_position.y, -3)
	control_area.body_entered.connect(control_traffic)
	
	strike_timer = Timer.new()
	add_child(strike_timer)
	strike_timer.one_shot = true
	strike_timer.wait_time = strike_duration
	strike_timer.timeout.connect(func(): _set_lights())
	
	_set_lights()
	
func _set_lights() -> void:
	const light_surface = 1
	if strike_timer.is_stopped():
		%PortalParticles.emitting = true
		%GateMesh.set_surface_override_material(light_surface, green_light_material)
	else:
		%PortalParticles.emitting = false
		%GateMesh.set_surface_override_material(light_surface, strike_light_material)
