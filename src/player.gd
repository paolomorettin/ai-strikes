class_name Player
extends Camera3D

@onready var game: Game = get_parent()

const EPSILON = 0.01

var next_camera_position: Vector3
var zoom_increment: float = 0.5

var selected: Node3D

func interact_primary() -> void:
	if selected != null and selected is Wheelchair and (selected as Wheelchair).current_state != Wheelchair.State.OVERRIDE:
		(selected as Wheelchair).die()

func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion:
		_raycast()
	
	if event.is_action_pressed("zoom_in"):
		next_camera_position.z -= zoom_increment
	elif event.is_action_pressed("zoom_out"):
		next_camera_position.z += zoom_increment
	elif event.is_action_pressed("primary"):
		interact_primary()


func _physics_process(delta: float) -> void:
	
	if Input.is_action_pressed("left"):
		next_camera_position.x -= zoom_increment
	if Input.is_action_pressed("right"):
		next_camera_position.x += zoom_increment
	if Input.is_action_pressed("down"):
		next_camera_position.y -= zoom_increment
	if Input.is_action_pressed("up"):
		next_camera_position.y += zoom_increment
	
	var direction: Vector3 = (next_camera_position - global_position)
	if direction.length() > EPSILON:
		global_position += direction * 0.5
	else:
		global_position = next_camera_position
		
func _raycast() -> void:
	var space_state = get_world_3d().direct_space_state
	var target_position = Plane(Vector3.BACK, Vector3.ZERO).intersects_ray(global_position, project_ray_normal(get_viewport().get_mouse_position()))
	var collision_mask: int = 4 # i.e. only objects
	var query = PhysicsRayQueryParameters3D.create(global_position, target_position, collision_mask)
	var result = space_state.intersect_ray(query)
	var collider = result.get("collider")
	# probably I should put conditions
	selected = collider

func _ready() -> void:
	global_position = Vector3(0, 0, 10)
	next_camera_position = global_position
