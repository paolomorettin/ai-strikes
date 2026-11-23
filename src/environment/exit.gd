class_name Exit
extends Node3D

@onready var control_area: Area3D = %ControlArea

var is_despawning: bool = false

var despawn_point: Vector3

func control_traffic(body: Node3D) -> void:
	if not (body is Wheelchair):
		return

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
	tween.tween_callback(func (): wheelchair.queue_free(); is_despawning = false)
	

func _ready() -> void:
	despawn_point = Vector3(global_position.x, global_position.y, -3)
	control_area.body_entered.connect(control_traffic)
