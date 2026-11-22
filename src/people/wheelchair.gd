class_name Wheelchair
extends CharacterBody3D

const THETA = deg_to_rad(5)

static var acceleration: float = 0.1 # m/s^2
static var deceleration: float = 0.3 # m/s^2
static var max_speed: float = 10.0 # m/s
static var turn_around_time: float = 1.0 # TAU/2*s

@onready var brake_lights: MeshInstance3D = %BrakeLights
@onready var halt_timer: Timer = %HaltTimer
@onready var main_mash: MeshInstance3D = %MainMesh
@onready var ttl_timer: Timer = %TTLTimer
@onready var sensing: Area3D = %Sensing

# particle factories
var explosions = preload("res://src/particles/explosion.tscn")
var sparks = preload("res://src/particles/sparks.tscn")

enum State {
	BRAKE, # braking
	IDLE, # initially or after turnaround
	MOVE, # increasing velocity or peaked
	OVERRIDE, # something took control
	ROTATE # turning around
}
var current_state: State:
	set(state):
		current_state = state
		_set_brake_lights(state)

var facing: Vector3 = Vector3.RIGHT


func die() -> void:
	var explosion: CPUParticles3D = explosions.instantiate()
	explosion.finished.connect(func(): explosion.queue_free())
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	explosion.emitting = true
	queue_free()
	

func disable_collisions() -> void:
	collision_layer = 0
	
func enable_collisions() -> void:
	collision_layer = 4

func turn_around() -> void:
	current_state = State.ROTATE
	var tween = get_tree().create_tween()
	var rotated_quaternion: Quaternion = quaternion * Quaternion(Vector3.UP, TAU/2)
	tween.tween_property(self, "quaternion", rotated_quaternion, turn_around_time)
	tween.tween_callback(func(): current_state = State.IDLE)

func _physics_process(delta: float) -> void:

	# update the facing vector
	facing = (quaternion * Vector3.RIGHT).normalized()

	# on the move, autonomously
	if not current_state in [State.ROTATE, State.OVERRIDE]:
		
		# TODO: this better be handled via signals / attributes rather than cycling all overlapping bodies
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
		
		# TODO: (MAYBE NOT NECESSARY) change this for arbitrary facing vectors
		if closest_obstacle == null or (
			closest_obstacle is CharacterBody3D and
			closest_obstacle.velocity.x * self.velocity.x > 0 and
			abs(closest_obstacle.velocity.x) - abs(self.velocity.x) > 0
		):
			# if the closest obstacle (if any) is moving in the same direction at higher speed
			if current_state != State.MOVE:
				current_state = State.MOVE
				halt_timer.stop()
		else:
			if current_state != State.BRAKE:
				current_state = State.BRAKE

	if is_on_floor():
		# handle horizontal velocity
		if current_state == State.BRAKE:
			if abs(velocity.x) > 0:
				velocity.x = sign(facing.x) * max(0.0, abs(velocity.x) - deceleration)
			else:
				if halt_timer.is_stopped():
					halt_timer.start()

		elif current_state == State.MOVE:
			velocity.x = sign(facing.x) * min(max_speed, abs(velocity.x) + acceleration)
			
		elif current_state in [State.OVERRIDE, State.ROTATE]:
			velocity.x = 0.0

	else:
		velocity += get_gravity()
	
	move_and_slide()
	if is_on_floor() and current_state != State.ROTATE:
		var floor_normal: Vector3 = get_floor_normal()
		if floor_normal.angle_to(quaternion * Vector3.UP) > THETA:
			quaternion = (Quaternion(Vector3.UP, floor_normal) * quaternion).normalized()

func _ready() -> void:
	brake_lights.mesh.material = StandardMaterial3D.new()
	halt_timer.timeout.connect(turn_around)
	ttl_timer.timeout.connect(die)
	ttl_timer.start()
	
	current_state = State.IDLE

func _set_brake_lights(state: State) -> void:
	if state in [State.IDLE, State.MOVE]:
		brake_lights.mesh.material.albedo_color = Color(0.2, 0.0, 0.0)
	elif state in [State.BRAKE, State.ROTATE]:
		brake_lights.mesh.material.albedo_color = Color(1.0, 0.0, 0.0)
	elif state == State.OVERRIDE:
		brake_lights.mesh.material.albedo_color = Color(0.0, 0.85, 0.7)
		
