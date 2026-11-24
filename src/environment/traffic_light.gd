class_name TrafficLight
extends StaticBody3D

@onready var green_light: MeshInstance3D = %GreenLight
@onready var red_light: MeshInstance3D = %RedLight
@onready var control_area: Area3D = %ControlArea

@export var is_green: bool = true
@export var switcher: Node = null # if not set, use a timer with 'default_duration'

var parking_space: float # m
var queue: Array[Wheelchair] = []
var queue_size: int

var selection_overlay_meshes: Array[MeshInstance3D] = []

static var default_duration: float = 5.0 # s (used when 'switcher' is not set)

static var green_light_material: StandardMaterial3D = preload("res://materials/green_light_material.tres")
var no_light_material: StandardMaterial3D = preload("res://materials/no_light_material.tres")
var red_light_material: StandardMaterial3D = preload("res://materials/red_light_material.tres")
static var strike_light_material: StandardMaterial3D = preload("res://materials/strike_light_material.tres")

static var strike_cost: int = 20
static var strike_duration: float = 4.0 # s

var buffered_change: bool = false
var strike_timer: Timer



func change_lights() -> void:
	
	if not strike_timer.is_stopped():
		buffered_change = true
		return
	
	is_green = not is_green
	_set_lights()
	
	if is_green:
		dispatch()

func control_traffic(body: Node3D) -> void:
	if not is_instance_valid(body):
		return
	
	if (body is Wheelchair) and not is_green:
		if len(queue) == 0 or (len(queue) < queue_size and (body as Wheelchair).facing.x * queue[0].facing.x > 0):
			park(body)
		else:
			(body as Wheelchair).turn_around()

func dispatch() -> void:
	# filter freed instances
	queue = queue.filter(func(x): return is_instance_valid(x))
	
	while len(queue) > 0:
		var wheelchair: Wheelchair = queue.pop_front()
		wheelchair.current_state = Wheelchair.State.IDLE

func park(wheelchair: Wheelchair) -> void:
	queue.append(wheelchair)
	wheelchair.current_state = Wheelchair.State.OVERRIDE
	
	# compute parking position and duration
	var offset: float = (len(queue) - 0.5) * parking_space
	var target_x: float
	if wheelchair.facing.x > 0:
		target_x = control_area.global_position.x + queue_size * parking_space / 2 - offset
	else:
		target_x = control_area.global_position.x - queue_size * parking_space / 2 + offset
		
	var parking_duration: float = 2 * abs(target_x - wheelchair.global_position.x) / wheelchair.max_speed
		
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(wheelchair, "position:x", target_x, parking_duration)

func strike() -> bool:
	if not strike_timer.is_stopped():
		return false
	else:
		strike_timer.start()
		_set_lights()
		return true



func _ready() -> void:
	
	selection_overlay_meshes = [%Pole, %Body]
	
	if switcher == null:
		switcher = Timer.new()
		add_child(switcher)
		switcher.wait_time = default_duration
		switcher.start()
		
	switcher.timeout.connect(change_lights)
	
	control_area.body_entered.connect(control_traffic)
	# TODO: compute parking space based on the wheelchair sensing distance
	parking_space = 1.3
	
	# compute queue size based on the control area size
	var control_area_size = (control_area.get_child(0).shape as BoxShape3D).size.x
	queue_size = int(control_area_size / parking_space)
	
	strike_timer = Timer.new()
	add_child(strike_timer)
	strike_timer.one_shot = true
	strike_timer.wait_time = strike_duration
	strike_timer.timeout.connect(
		func():
			if buffered_change:
				buffered_change = false
				change_lights()
	)
	
	#green_light_material = StandardMaterial3D.new()
	#green_light_material.albedo_color = Color(0, 0.3, 0)
	#green_light_material.emission_enabled = true
	#green_light_material.emission_energy_multiplier = 3.0
	#green_light_material.emission = Color(0, 1, 0)
	#
	#no_light_material = StandardMaterial3D.new()
	#no_light_material.albedo_color = Color(0.3, 0.3, 0.5)
	#
	#red_light_material = StandardMaterial3D.new()
	#red_light_material.albedo_color = Color(0.3, 0, 0)
	#red_light_material.emission_enabled = true
	#red_light_material.emission_energy_multiplier = 3.0
	#red_light_material.emission = Color(1, 0, 0)
	
	_set_lights()

func _set_lights() -> void:
	if is_green:
		red_light.material_override = no_light_material
		if strike_timer.is_stopped():
			green_light.material_override = green_light_material
		else:
			green_light.material_override = strike_light_material
	else:
		green_light.material_override = no_light_material
		if strike_timer.is_stopped():
			red_light.material_override = red_light_material
		else:
			red_light.material_override = strike_light_material
