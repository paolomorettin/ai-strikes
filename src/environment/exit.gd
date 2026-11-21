class_name Exit
extends Node3D

@onready var control_area: Area3D = %ControlArea

var currently_serving = null:
	set(wheelchair):
		currently_serving = wheelchair
		if wheelchair != null:
			serve(wheelchair)

var queue: Array[Wheelchair] = []

func control_body(body: Node3D) -> void:
	if not (body is Wheelchair):
		return
		
	(body as Wheelchair).current_state = Wheelchair.State.OVERRIDE
	if currently_serving == null:
		currently_serving = body
	else:
		queue.append(body)
		
func remove_current() -> void:
	(currently_serving as Node).queue_free()
	currently_serving = queue.pop_front()
	
func serve(wheelchair: Wheelchair) -> void:
	wheelchair.disable_collisions()
	var horizontal_movement_duration = wheelchair.global_position.distance_to(global_position) / abs(wheelchair.velocity.x)
	var despawn_point = Vector3(global_position.x, global_position.y, -4.0)
	var despawn_duration = -despawn_point.z / abs(wheelchair.velocity.x)
	var target_rotation: float = TAU / 4
	if wheelchair.global_position.x > global_position.x:
		target_rotation = -target_rotation
	
	var tween = get_tree().create_tween()
	# x-movement to exit
	tween.tween_property(wheelchair, "global_position", global_position, horizontal_movement_duration)
	# rotation towards exit
	tween.tween_property(wheelchair, "rotation:y", target_rotation, wheelchair.turn_around_time / 2.0)
	# z-movement to exit
	tween.tween_property(wheelchair, "global_position", despawn_point, despawn_duration)
	tween.tween_callback(remove_current)
	

func _ready() -> void:
	control_area.body_entered.connect(control_body)
