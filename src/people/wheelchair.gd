class_name Wheelchair
extends CharacterBody3D

@onready var brakes: TrafficLight = %Brakes
@onready var brake_lights: MeshInstance3D = %BrakeLights
@onready var halt_timer: Timer = %HaltTimer
@onready var sensing: Area3D = %Sensing

enum States {BRAKE, HALT, IDLE, MOVE, ROTATE}
var current_state: States
var current_direction: int = 1

var acceleration: float = 0.6 # m/s^2
var deceleration: float = 2.0 # m/s^2
var max_speed: float = 10.0 # m/s
var rotation_speed: float = 1.0 # TAU/2*s

func explode() -> void:
	var tween = get_tree().create_tween()
	var eps = 0.01
	var delta = 0.1
	for i in range(10):
		var random_pos: Vector3 = position + Vector3(randf_range(-eps, eps), randf_range(-eps, eps), randf_range(-eps, eps))
		tween.tween_property(self, "position", random_pos, delta)
	tween.tween_callback(queue_free)

func turn_around() -> void:
	current_state = States.ROTATE
	var tween = get_tree().create_tween()
	var rotated_quaternion: Quaternion = Quaternion(Vector3.UP, TAU/2) * quaternion
	tween.tween_property(self, "quaternion", rotated_quaternion, rotation_speed)
	tween.tween_callback(func(): current_direction = -current_direction; current_state = States.IDLE)

func _physics_process(delta: float) -> void:

	# computes the closest obstacle ahead (if any)
	var obstacles_ahead: Array[Node3D] = sensing.get_overlapping_bodies()
	obstacles_ahead = obstacles_ahead.filter(func(obj): return obj != self)
	var closest_obstacle = null
	var min_dist = null
	for obs in obstacles_ahead:
		var dist = obs.global_position.distance_squared_to(self.global_position)
		if closest_obstacle == null or dist < min_dist:
			closest_obstacle = obs
			min_dist = dist
	
	if current_state != States.ROTATE:
		if closest_obstacle == null or (
			closest_obstacle is CharacterBody3D and
			closest_obstacle.velocity.x * self.velocity.x > 0 and
			abs(closest_obstacle.velocity.x) - abs(self.velocity.x) > 0
		):
			# if the closest obstacle (if any) is moving in the same direction at higher speed
			if current_state != States.MOVE:
				_set_brake_lights(false)
				current_state = States.MOVE
				halt_timer.stop()
		else:
			if current_state != States.BRAKE:
				_set_brake_lights(true)
				current_state = States.BRAKE
	
	# move horizontally according to 'current_state'
	if is_on_floor():
		if current_state == States.BRAKE:
			velocity.x = current_direction * max(0.0, abs(velocity.x) - deceleration * delta)
			if abs(velocity.x) == 0 and halt_timer.is_stopped():
				halt_timer.start()
		elif current_state == States.MOVE:
			velocity.x = current_direction * min(max_speed, abs(velocity.x) + acceleration * delta)

	else:
		velocity += get_gravity()
	
	move_and_slide()

func _ready() -> void:
	brake_lights.mesh.material = StandardMaterial3D.new()
	halt_timer.timeout.connect(turn_around)
	current_state = States.IDLE

func _set_brake_lights(braking: bool) -> void:
	brakes.stop = braking
	if braking:
		brake_lights.mesh.material.albedo_color = Color(1.0, 0.0, 0.0)
	else:
		brake_lights.mesh.material.albedo_color = Color(0.2, 0.0, 0.0)
