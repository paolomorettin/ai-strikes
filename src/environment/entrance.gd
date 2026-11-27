class_name Entrance
extends Node3D

enum Direction {LEFT, RIGHT}

static var strike_cost: int = 15
static var strike_duration: float = 15.0 # s

@export var direction: Direction = Direction.RIGHT
@export var spawn_time: float = 10.0 # s

@onready var control_area: Area3D = %ControlArea

var last_spawned
var is_spawning: bool = false
var spawn_point: Vector3
var spawn_timer: Timer
var strike_timer: Timer

##### GRAPHICS
var green_light_material: StandardMaterial3D = preload("res://materials/green_light_material.tres")
var no_light_material: StandardMaterial3D = preload("res://materials/no_light_material.tres")
var strike_light_material: StandardMaterial3D = preload("res://materials/strike_light_material.tres")

@onready var selection_overlay_meshes: Array[MeshInstance3D] = [%GateMesh]

func control_traffic(body: Node3D) -> void:
	if not (body is Wheelchair) or body == last_spawned:
		return
	if is_spawning:
		(body as Wheelchair).turn_around()

func spawn() -> void:
	# ensure no wheelchairs are around
	for body in control_area.get_overlapping_bodies():
		if body is Wheelchair:
			return

	is_spawning = true
	last_spawned = preload("res://src/wheelchair.tscn").instantiate()
	var level: Node3D = get_parent()
	last_spawned.position = level.to_local(spawn_point)
	level.add_child(last_spawned)

	last_spawned.current_state = Wheelchair.State.OVERRIDE
	last_spawned.quaternion = Quaternion(Vector3.UP, -TAU/4)
	
	var spawn_duration = -spawn_point.z / (0.5 * Wheelchair.max_speed)
	var target_quaternion: Quaternion
	
	if strike_timer.is_stopped():
		match direction:
			Direction.LEFT:
				target_quaternion = Quaternion(Vector3.UP, TAU / 2)
			Direction.RIGHT:
				target_quaternion = Quaternion()
	else:
		if randf() > 0.5:
			target_quaternion = Quaternion(Vector3.UP, TAU / 2)
		else:
			target_quaternion = Quaternion()

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
	
func can_strike() -> bool:
	return strike_timer.is_stopped()
	
func strike() -> void:
	strike_timer.start()
	_set_lights()


func _ready() -> void:
	spawn_point = Vector3(global_position.x, global_position.y, -3)
	control_area.body_entered.connect(control_traffic)
	
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_time
	spawn_timer.timeout.connect(spawn)
	spawn_timer.start()
	
	strike_timer = Timer.new()
	add_child(strike_timer)
	strike_timer.one_shot = true
	strike_timer.wait_time = strike_duration
	strike_timer.timeout.connect(func(): _set_lights())
	
	_set_lights()
	
func _set_lights() -> void:
	const left_surface = 1
	const right_surface = 2
	if strike_timer.is_stopped():
		if direction == Direction.LEFT:
			%GateMesh.set_surface_override_material(left_surface, green_light_material)
			%GateMesh.set_surface_override_material(right_surface, no_light_material)
		elif direction == Direction.RIGHT:
			%GateMesh.set_surface_override_material(left_surface, no_light_material)
			%GateMesh.set_surface_override_material(right_surface, green_light_material)
	else:
		%GateMesh.set_surface_override_material(left_surface, strike_light_material)
		%GateMesh.set_surface_override_material(right_surface, strike_light_material)
