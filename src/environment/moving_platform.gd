class_name MovingPlatform
extends AnimatableBody3D

const EPSILON = 0.01

const PARKING_SPACE = 1.3

enum Direction {LEFT, RIGHT}
enum State {UNLOAD, LOAD, MOVE, STRIKE}

static var strike_cost: int = 15
static var strike_duration: float = 5.0 # s

@export var stops: Array[MovingPlatformStop]
@export var traffic_lights: Array[TrafficLight]
@export var max_speed: float = 3.0 # m/s

@onready var control_area: Area3D = %ControlArea

var current_state: State:
	set(value):
		current_state = value
		if value == State.MOVE:
			if not stream_player.playing:
				stream_player.play()
			else:
				stream_player.stream_paused = false
		else:
			stream_player.stream_paused = true

var current_stop: int = 0
var idle_timer: Timer
var strike_timer: Timer
var queue: Array[Wheelchair]
var queue_size: int
var is_striking: bool = false

##### GRAPHICS
var green_light_material: StandardMaterial3D = preload("res://materials/green_light_material.tres")
var no_light_material: StandardMaterial3D = preload("res://materials/no_light_material.tres")
var red_light_material: StandardMaterial3D = preload("res://materials/red_light_material.tres")
var strike_light_material: StandardMaterial3D = preload("res://materials/strike_light_material.tres")

@onready var selection_overlay_meshes: Array[MeshInstance3D] = [%Mesh]

##### AUDIO
static var sound: AudioStream = preload("res://sounds/motion.wav")
var stream_player: AudioStreamPlayer3D

func depart():
	var current_traffic_light = traffic_lights[current_stop]
	if current_traffic_light != null:
		current_traffic_light.turn_red()
	
	current_state = State.MOVE
	if not is_striking:
		%Mesh.set_surface_override_material(3, no_light_material)
	current_stop = (current_stop + 1) % len(stops)

func load_platform() -> void:
	current_state = State.LOAD
	if not is_striking:
		%Mesh.set_surface_override_material(3, green_light_material)
	idle_timer.wait_time = stops[current_stop].idle_time
	idle_timer.start()


func unload_platform() -> void:
	var current_traffic_light = traffic_lights[current_stop]
	if current_traffic_light != null:
		current_traffic_light.turn_green()
		
	if is_striking:
		is_striking = false

	if len(queue) > 0 :
		current_state = State.UNLOAD
		%Mesh.set_surface_override_material(3, red_light_material)
		for wc in queue:
			if is_instance_valid(wc):
				wc.current_state = Wheelchair.State.MOVE
	else:
		load_platform()
		
func park(wheelchair: Wheelchair) -> void:
	queue.append(wheelchair)
	wheelchair.current_state = Wheelchair.State.OVERRIDE
	
	# compute parking position and duration
	var offset: float = (len(queue) - 0.5) * PARKING_SPACE
	var target_x: float
	if wheelchair.facing.x > 0:
		target_x = control_area.global_position.x + queue_size * PARKING_SPACE / 2 - offset
	else:
		target_x = control_area.global_position.x - queue_size * PARKING_SPACE / 2 + offset
		
	var parking_duration: float = 2 * abs(target_x - wheelchair.global_position.x) / wheelchair.max_speed
		
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(wheelchair, "position:x", target_x, parking_duration)
	
func can_strike() -> bool:
	return not is_striking
	
func strike() -> void:
	is_striking = true
	%Mesh.set_surface_override_material(3, strike_light_material)
	current_stop = (current_stop + 1) % len(stops)


func _body_entered(body: Node3D) -> void:
	if not (body is Wheelchair) or current_state != State.LOAD:
		return
	
	var wc: Wheelchair = body as Wheelchair
	if len(queue) < queue_size:
		
		if (
			(stops[current_stop].load_direction == Direction.LEFT and wc.facing.x > 0) or 
			(stops[current_stop].load_direction == Direction.RIGHT and wc.facing.x < 0)
		):
			park(wc)
		else:
			wc.turn_around()

func _body_exited(body: Node3D) -> void:
	if not (body is Wheelchair):
		return
		
	queue.erase(body)
	if len(queue) == 0 and current_state == State.UNLOAD:
		load_platform()

func _physics_process(delta: float) -> void:
	
	var velocity: Vector3 = Vector3.ZERO
	
	if current_state == State.MOVE:
		var current_stop_position: Vector3 = stops[current_stop].position
		var current_stop_distance: float = global_position.distance_to(current_stop_position)
		if current_stop_distance < EPSILON:
			global_position = current_stop_position
			unload_platform()
		else:
			var current_stop_direction: Vector3 = (current_stop_position - global_position) / current_stop_distance
			velocity = current_stop_direction * clampf(current_stop_distance, EPSILON / delta, max_speed) * delta
			position += velocity
			
func _ready() -> void:
	while len(stops) > len(traffic_lights):
		traffic_lights.append(null)
	
	control_area.body_entered.connect(_body_entered)
	control_area.body_exited.connect(_body_exited)
	idle_timer = Timer.new()
	add_child(idle_timer)
	idle_timer.one_shot = true
	idle_timer.timeout.connect(depart)
	
	# compute queue size based on the control area size
	var control_area_size = (control_area.get_child(0).shape as BoxShape3D).size.x
	queue_size = int(control_area_size / PARKING_SPACE)
	
	stream_player = AudioStreamPlayer3D.new()
	add_child(stream_player)
	stream_player.stream = sound
	
	current_state = State.MOVE
