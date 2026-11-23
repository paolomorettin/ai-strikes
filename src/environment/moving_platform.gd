class_name MovingPlatform
extends AnimatableBody3D

enum Mode {LEFT_LEFT, LEFT_RIGHT, RIGHT_LEFT, RIGHT_RIGHT}

enum State {OPEN, CLOSED, MOVING}
var current_state: State


@export var mode: Mode = Mode.LEFT_LEFT
@export var endpoint: Vector3
@export var travel_speed: float = 3.0 # m/s

@onready var idle_timer: Timer = %IdleTimer
@onready var platform: AnimatableBody3D = %Platform

var endpoints_distance: float
var startpoint: Vector3

var platform_size: float
var control_areas: Array[Area3D]
var queues: Array
var max_queue_size: int

func control_body(area_index: int, body: Node3D) -> void:
	if not (body is Wheelchair):
		return
		
	var wc: Wheelchair = body
	
	wc.current_state = Wheelchair.State.OVERRIDE
	
func move() -> void:
	current_state = State.MOVING
	var tween = get_tree().create_tween()
	var target_position: Vector3
	if platform.position == startpoint:
		target_position = endpoint
	elif platform.position == endpoint:
		target_position = startpoint
	
	# TODO: change to something more smooth
	tween.tween_property(platform, "position", target_position, endpoints_distance / travel_speed)
	tween.tween_callback(unload_platform)

func load_platform() -> void:
	pass
	
func unload_platform() -> void:
	pass

func _ready() -> void:
	startpoint = position
	endpoints_distance = startpoint.distance_to(endpoint)
	
	# TODO: change
	platform_size = ((platform.get_child(0) as CollisionShape3D).shape as BoxShape3D).size.x
	
	# initialize (start/end/platform) queues
	queues = [[], [], []]
	
	# initialize control areas and shapes
	var extreme_points: Array[Vector3] = [startpoint, endpoint]
	var sides: Array[int]
	match mode:
		Mode.LEFT_LEFT: sides = [-1, -1]
		Mode.LEFT_RIGHT: sides = [-1, 1]
		Mode.RIGHT_LEFT: sides = [1, -1]
		Mode.RIGHT_RIGHT: sides = [1, 1]
	
	for i in range(2):
		var control_area = Area3D.new()
		add_child(control_area)
		control_area.position = extreme_points[i]
		control_areas.append(control_area)
		control_area.body_entered.connect(func (body): control_body(i, body))

		var collision_shape = CollisionShape3D.new()
		control_area.add_child(collision_shape)
		collision_shape.position.x += sides[i] * platform_size
		collision_shape.shape = BoxShape3D.new()
		(collision_shape.shape as BoxShape3D).size = Vector3(platform_size, 1.0, 1.0)
