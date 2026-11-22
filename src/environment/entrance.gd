class_name Entrance
extends Node3D

enum Direction {LEFT, RIGHT, RANDOM}

@onready var control_area: Area3D = %ControlArea
@onready var spawn_timer: Timer = %SpawnTimer

@export var spawn_speed: float = 0.5 # relative to 'Wheelchair.max_speed'
@export var direction: Direction = Direction.RANDOM

var last_spawned
var is_spawning: bool = false

var spawn_point: Vector3

func control_traffic(body: Node3D) -> void:
	if not (body is Wheelchair) or body == last_spawned:
		return
	if is_spawning:
		(body as Wheelchair).turn_around()

func actual_spawn() -> void:
	last_spawned.current_state = Wheelchair.State.OVERRIDE
	last_spawned.global_position = spawn_point
	last_spawned.quaternion = Quaternion(Vector3.UP, -TAU/4)
	#last_spawned.disable_collisions()
	
	var spawn_duration = -spawn_point.z / (spawn_speed * Wheelchair.max_speed)
	var target_quaternion: Quaternion
	match direction:
		Direction.LEFT:
			target_quaternion = Quaternion(Vector3.UP, TAU / 2)
		Direction.RIGHT:
			target_quaternion = Quaternion()
		Direction.RANDOM:
			target_quaternion = Quaternion(Vector3.UP, int(randf() > 0.5) * TAU / 2)
	
	var tween = get_tree().create_tween()
	# z-movement from entrance
	tween.tween_property(last_spawned, "global_position:z", global_position.z, spawn_duration)
	# rotation towards exit
	tween.tween_property(last_spawned, "quaternion", target_quaternion, Wheelchair.turn_around_time / 2.0)
	tween.tween_callback(
		func (): 
			is_spawning = false
			last_spawned.current_state = Wheelchair.State.IDLE; 
	)


func tentative_spawn() -> void:
	# ensure no wheelchairs are around
	for body in control_area.get_overlapping_bodies():
		if body is Wheelchair:
			return

	is_spawning = true
	last_spawned = preload("res://src/people/wheelchair.tscn").instantiate()
	get_parent().add_child(last_spawned)
	call_deferred("actual_spawn")
	
func _ready() -> void:
	spawn_point = Vector3(global_position.x, global_position.y, -3)
	control_area.body_entered.connect(control_traffic)
	spawn_timer.timeout.connect(tentative_spawn)
