class_name Wheelchair
extends CharacterBody3D

const THETA = deg_to_rad(5)

static var acceleration: float = 0.05 # m/s^2
static var deceleration: float = 0.15 # m/s^2
static var max_speed: float = 4.0 # m/s
static var turn_around_time: float = 1.0 # TAU/2*s

static var mayhem_score: int = 10
static var strike_cost: int = 15
static var strike_turn_arounds: int = 8 # happening twice as fast wrt 'turn_around_time'

var strike_buffered: bool = false # needed for buffering a strike during an autonomous rotation

@onready var game: Game = get_parent().get_parent()

@onready var brake_lights: MeshInstance3D = %BrakeLights
@onready var halt_timer: Timer = %HaltTimer
@onready var ttl_timer: Timer = %TTLTimer
@onready var sensing: Area3D = %Sensing


# particles
static var explosions = preload("res://particles/explosion.tscn")
static var sparks = preload("res://particles/sparks.tscn")

# materials
static var no_light_material = preload("res://materials/no_light_material.tres")
static var override_light_material = preload("res://materials/override_light_material.tres")
static var red_light_material = preload("res://materials/red_light_material.tres")
static var strike_light_material = preload("res://materials/strike_light_material.tres")

var selection_overlay_meshes: Array[MeshInstance3D] = []


enum State {
	BRAKE, # braking
	IDLE, # initially or after turnaround
	MOVE, # increasing velocity or peaked
	OVERRIDE, # something took control
	ROTATE, # turning around
	STRIKE # rotating in place
}
var current_state: State:
	set(state):
		current_state = state
		_set_brake_lights(state)

# normalized direction vectors updated during '_physics_process'
var facing: Vector3
var up: Vector3


func die() -> void:
	var explosion: CPUParticles3D = explosions.instantiate()
	explosion.finished.connect(func(): explosion.queue_free())
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	explosion.emitting = true
	game.score(mayhem_score)
	call_deferred("queue_free")
	
func strike() -> bool:
	if current_state == State.OVERRIDE or current_state == State.STRIKE:
		return false
	elif current_state == State.ROTATE and not strike_buffered:
		strike_buffered = true
		return true
	else:
		current_state = State.STRIKE
		var tween: Tween = get_tree().create_tween()
		var target_quaternion: Quaternion = quaternion
		for n in range(strike_turn_arounds):
			target_quaternion = Quaternion(Vector3.UP, PI) * target_quaternion
			tween.tween_property(self, "quaternion", target_quaternion, turn_around_time / 2.0)
			
		tween.tween_callback(func (): current_state = State.IDLE)
		return true

func turn_around() -> void:
	if current_state == State.STRIKE:
		return

	current_state = State.ROTATE
	var tween = get_tree().create_tween()
	var rotated_quaternion: Quaternion = quaternion * Quaternion(Vector3.UP, TAU/2)
	tween.tween_property(self, "quaternion", rotated_quaternion, turn_around_time)
	tween.tween_callback(func(): 
		current_state = State.IDLE
		if strike_buffered:
			strike_buffered = false
			strike()
	)

func _physics_process(delta: float) -> void:

	##### update the facing and up vector

	facing = (quaternion * Vector3.RIGHT).normalized()
	up = (quaternion * Vector3.UP).normalized()

	##### handle autonomous movement state transition

	if not current_state in [State.OVERRIDE, State.ROTATE, State.STRIKE]:
		
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

	##### set physical quantities

	var was_flying: bool = not is_on_floor()
	
	if not was_flying:
		# handle horizontal velocity
		if current_state == State.BRAKE:
			if abs(velocity.x) > 0:
				velocity.x = sign(facing.x) * max(0.0, abs(velocity.x) - deceleration)
			else:
				if halt_timer.is_stopped():
					halt_timer.start()

		elif current_state == State.MOVE:
			velocity.x = sign(facing.x) * min(max_speed, abs(velocity.x) + acceleration)
			
		elif current_state in [State.OVERRIDE, State.ROTATE, State.STRIKE]:
			velocity.x = 0.0

	else:
		velocity += get_gravity() * delta
		
	
	var velocity_y_delta: float = velocity.y
	move_and_slide()
	
	# impact with floor
	if was_flying and is_on_floor():
		prints("velocity_y_delta at impact", velocity_y_delta)
		if abs(velocity_y_delta) > abs(get_gravity().y) * 1.0:
			die()
		
	# adjust the up direction wrt the floor
	if is_on_floor() and current_state != State.ROTATE:
		var floor_normal: Vector3 = get_floor_normal()
		if floor_normal.angle_to(up) > THETA:
			quaternion = (Quaternion(up, floor_normal) * quaternion).normalized()

func _ready() -> void:
	
	selection_overlay_meshes = [%MainMesh, %BrakeLights]
	
	brake_lights.mesh.material = StandardMaterial3D.new()
	halt_timer.timeout.connect(turn_around)
	ttl_timer.timeout.connect(die)
	ttl_timer.start()
	
	current_state = State.IDLE

func _set_brake_lights(state: State) -> void:
	if state in [State.IDLE, State.MOVE]:
		brake_lights.mesh.material = no_light_material
	elif state in [State.BRAKE, State.ROTATE]:
		brake_lights.mesh.material = red_light_material
	elif state == State.OVERRIDE:
		brake_lights.mesh.material = override_light_material
	elif state == State.STRIKE:
		brake_lights.mesh.material = strike_light_material
		
