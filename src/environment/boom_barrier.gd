class_name BoomBarrier
extends StaticBody3D

static var strike_cost: int = 20
static var strike_duration: float = 15.0 # s

var strike_timer: Timer

##### GRAPHICS

@onready var selection_overlay_meshes: Array[MeshInstance3D] = [%Bar, %Column]

static var red_light_material: StandardMaterial3D = preload("res://materials/red_light_material.tres")
static var strike_light_material: StandardMaterial3D = preload("res://materials/strike_light_material.tres")

func can_strike() -> bool:
	return strike_timer.is_stopped()
	

func strike():
	strike_timer.start()
	_toggle()
	
func _ready() -> void:
	strike_timer = Timer.new()
	add_child(strike_timer)
	strike_timer.one_shot = true
	strike_timer.wait_time = strike_duration
	strike_timer.timeout.connect(_toggle)
	
func _toggle() -> void:
	
	var tween: Tween = get_tree().create_tween()
	var target_quaternion: Quaternion
	
	target_quaternion = Quaternion(Vector3.RIGHT, -int(not strike_timer.is_stopped()) * TAU/4)
	tween.tween_property(%Bar, "quaternion", target_quaternion, 0.5)
	
	const light_surface = 1
	
	if strike_timer.is_stopped():
		collision_layer = 2
		%Column.set_surface_override_material(light_surface, red_light_material)
		%Bar.set_surface_override_material(light_surface, red_light_material)
	else:
		collision_layer = 0
		%Column.set_surface_override_material(light_surface, strike_light_material)
		%Bar.set_surface_override_material(light_surface, strike_light_material)
