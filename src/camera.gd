class_name Camera
extends Camera3D

const EPSILON = 0.01

var target_position: Vector3

var zoom_increment: float = 0.5


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		target_position.z -= zoom_increment
	elif event.is_action_pressed("zoom_out"):
		target_position.z += zoom_increment


func _physics_process(delta: float) -> void:
	
	if Input.is_action_pressed("left"):
		target_position.x -= zoom_increment
	if Input.is_action_pressed("right"):
		target_position.x += zoom_increment
	if Input.is_action_pressed("down"):
		target_position.y -= zoom_increment
	if Input.is_action_pressed("up"):
		target_position.y += zoom_increment
	
	var direction: Vector3 = (target_position - global_position)
	if direction.length() > EPSILON:
		global_position += direction * 0.5
	else:
		global_position = target_position

func _ready() -> void:
	target_position = global_position
