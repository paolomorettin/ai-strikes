class_name TrafficLight
extends Node3D

@onready var green_light: MeshInstance3D = %GreenLight
@onready var red_light: MeshInstance3D = %RedLight
@onready var control_area: Area3D = %ControlArea

@export var is_green: bool = true
@export var parking_space: float = 1.1 # m

var queue: Array[Wheelchair] = []
var queue_size: int

var green_light_material: StandardMaterial3D
var no_light_material: StandardMaterial3D
var red_light_material: StandardMaterial3D

signal switched

func control_traffic(body: Node3D) -> void:
	if (body is Wheelchair) and not is_green:
		if len(queue) == 0 or (len(queue) < queue_size and (body as Wheelchair).facing.x * queue[0].facing.x > 0):
			park(body)
		else:
			(body as Wheelchair).turn_around()

func dispatch() -> void:
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

func switch() -> void:
	switched.emit()
	is_green = not is_green
	_set_lights()
	
	if is_green:
		dispatch()


func _ready() -> void:
	green_light_material = StandardMaterial3D.new()
	green_light_material.albedo_color = Color(0, 0.7, 0)
	green_light_material.emission_enabled = true
	green_light_material.emission_energy_multiplier = 3.0
	green_light_material.emission = Color(0, 1, 0)
	
	no_light_material = StandardMaterial3D.new()
	no_light_material.albedo_color = Color(0.3, 0.3, 0.5)
	
	red_light_material = StandardMaterial3D.new()
	red_light_material.albedo_color = Color(0.7, 0, 0)
	red_light_material.emission_enabled = true
	red_light_material.emission_energy_multiplier = 3.0
	red_light_material.emission = Color(1, 0, 0)
	
	_set_lights()
	
	control_area.body_entered.connect(control_traffic)
	
	# compute queue size based on the control area size
	var control_area_size = (control_area.get_child(0).shape as BoxShape3D).size.x
	queue_size = int(control_area_size / parking_space)

func _set_lights() -> void:
	if is_green:
		green_light.material_override = green_light_material
		red_light.material_override = no_light_material
	else:
		green_light.material_override = no_light_material
		red_light.material_override = red_light_material
