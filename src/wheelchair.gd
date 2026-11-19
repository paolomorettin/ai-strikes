class_name Wheelchair
extends CharacterBody3D


enum States {HALT, MOVE, ROTATE}
var current_state: States
var current_direction: int = 1

var speed: float = 1.0 # m/s

func _physics_process(delta: float) -> void:
	match current_state:
		States.MOVE:
			if is_on_floor():
				velocity.x = current_direction * speed
		States.ROTATE:
			pass
		States.HALT:
			velocity = Vector3.ZERO
			
	if not is_on_floor():
		velocity += get_gravity()
		
	move_and_slide()

func _ready() -> void:
	current_state = States.MOVE
