class_name TrafficLight
extends StaticBody3D

enum TrafficDirection {LEFT, RIGHT, UNSET}

const PARKING_SPACE = 1.3 # m

static var strike_cost: int = 10
static var strike_duration: float = 10.0 # s

@onready var control_area: Area3D = %ControlArea

@export var is_green: bool = true
@export var auto_switch_time: float = -1 # s (if greater than zero, sets a timer for automatic light switching)

var buffered_change: bool = false
var strike_timer: Timer

var queue: Array[Wheelchair] = []
var queue_size: int
var traffic_direction: TrafficDirection = TrafficDirection.UNSET

##### GRAPHICS

@onready var selection_overlay_meshes: Array[MeshInstance3D] = [%TrafficLightMain]

static var green_light_material: StandardMaterial3D = preload("res://materials/green_light_material.tres")
var no_light_material: StandardMaterial3D = preload("res://materials/no_light_material.tres")
var red_light_material: StandardMaterial3D = preload("res://materials/red_light_material.tres")
static var strike_light_material: StandardMaterial3D = preload("res://materials/strike_light_material.tres")

func turn_green() -> void:
	if not is_green:
		switch_lights()
		
func turn_red() -> void:
	if is_green:
		switch_lights()

func switch_lights() -> void:
	
	if not strike_timer.is_stopped():
		buffered_change = true
		return
	
	is_green = not is_green
	_set_lights()
	
	if is_green:
		dispatch()


func dispatch() -> void:
	# filter freed instances
	queue = queue.filter(func(x): return is_instance_valid(x))
	
	for wc in queue:
		wc.current_state = Wheelchair.State.IDLE

func park(wheelchair: Wheelchair) -> void:
	queue.append(wheelchair)
	wheelchair.current_state = Wheelchair.State.OVERRIDE
	
	# compute parking position and duration
	var offset: float = (len(queue) - 0.5) * PARKING_SPACE
	var target_x: float
	match traffic_direction:
		TrafficDirection.RIGHT:
			target_x = control_area.global_position.x + queue_size * PARKING_SPACE / 2 - offset
		TrafficDirection.LEFT:
			target_x = control_area.global_position.x - queue_size * PARKING_SPACE / 2 + offset
		
	var parking_duration: float = 2 * abs(target_x - wheelchair.global_position.x) / wheelchair.max_speed
		
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(wheelchair, "position:x", target_x, parking_duration)

func can_strike() -> bool:
	return strike_timer.is_stopped()

func strike():
	strike_timer.start()
	_set_lights()



func _body_entered(body: Node3D) -> void:
	if not is_instance_valid(body) or not (body is Wheelchair):
		return
	
	var wc: Wheelchair = (body as Wheelchair)
	
	# if traffic direction is unassigned, assign it
	if traffic_direction == TrafficDirection.UNSET:
		if wc.facing.x > 0:
			traffic_direction = TrafficDirection.RIGHT
		else:
			traffic_direction = TrafficDirection.LEFT
			
	# green means brrrr
	if is_green:
		return
	
	# is red and wrond direction
	if (
		(wc.facing.x > 0 and traffic_direction == TrafficDirection.LEFT) or 
		(wc.facing.x < 0 and traffic_direction == TrafficDirection.RIGHT)
	):
		wc.turn_around()
	else: # is red and right
		if len(queue) == queue_size:
			wc.turn_around()
		else:
			park(wc)

func _body_exited(body: Node3D) -> void:
	if not is_instance_valid(body) or not (body is Wheelchair):
		return
		
	# somebody is still inside
	for other_body in queue.filter(func(x): return is_instance_valid(x) and x != body):
		queue.erase(body)
		return
		
	# last one to exit, unset the traffic direction and empty the queue
	queue = []
	traffic_direction = TrafficDirection.UNSET

func _ready() -> void:
	if auto_switch_time > 0:
		var auto_switcher = Timer.new()
		add_child(auto_switcher)
		auto_switcher.wait_time = auto_switch_time
		auto_switcher.start()
		auto_switcher.timeout.connect(switch_lights)
	
	control_area.body_entered.connect(_body_entered)
	control_area.body_exited.connect(_body_exited)
	
	# compute queue size based on the control area size
	var control_area_size = (control_area.get_child(0).shape as BoxShape3D).size.x
	queue_size = int(control_area_size / PARKING_SPACE)
	
	strike_timer = Timer.new()
	add_child(strike_timer)
	strike_timer.one_shot = true
	strike_timer.wait_time = strike_duration
	strike_timer.timeout.connect(
		func():
			if buffered_change:
				buffered_change = false
				switch_lights()
	)
	_set_lights()

func _set_lights() -> void:
	if is_green:
		%TrafficLightMain.set_surface_override_material(2, no_light_material)
		if strike_timer.is_stopped():
			%TrafficLightMain.set_surface_override_material(3, green_light_material)
		else:
			%TrafficLightMain.set_surface_override_material(3, strike_light_material)
	else:
		%TrafficLightMain.set_surface_override_material(3, no_light_material)
		if strike_timer.is_stopped():
			%TrafficLightMain.set_surface_override_material(2, red_light_material)
		else:
			%TrafficLightMain.set_surface_override_material(2, strike_light_material)
