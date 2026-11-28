class_name Player
extends Camera3D

@onready var game: Game = get_parent()

const EPSILON = 0.01

var next_camera_position: Vector3
var planar_increment: float = 0.5
var zoom_levels: Array[float] = [50, 10, 5]
var current_zoom: int = 1

var selection_material: StandardMaterial3D = preload("res://materials/selection.tres")

##### AUDIO
static var strike_sound: AudioStream = preload("res://sounds/strike.wav")
var stream_player: AudioStreamPlayer

var selected: Node3D:
	set(value):
		if selected != null:
			for meshinstance in selected.selection_overlay_meshes:
				meshinstance.material_overlay = null
				
		if value == null:
			selected = null
		
		elif (
			"strike_cost" in value and
			"selection_overlay_meshes" in value and 
			value.has_method("can_strike") and
			value.has_method("strike")
		):
			selected = value
			for meshinstance in selected.selection_overlay_meshes:
				meshinstance.material_overlay = selection_material
		

func interact_primary() -> void:
	if selected == null:
		return
	if "strike_cost" in selected and selected.has_method("strike"):
		if game.strokens > selected.strike_cost:
			if selected.can_strike():
				selected.strike()
				# audio cue
				stream_player.play()
				game.strokens -= selected.strike_cost
		else:
			game.game_ui.tilt_control(game.game_ui.strokens_info)

func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion:
		_raycast()
	
	if event.is_action_pressed("zoom_in"):
		current_zoom = clampi(current_zoom + 1, 0, len(zoom_levels) - 1)
	elif event.is_action_pressed("zoom_out"):
		current_zoom = clampi(current_zoom - 1, 0, len(zoom_levels) - 1)
	elif event.is_action_pressed("primary"):
		interact_primary()
		
	next_camera_position.z = zoom_levels[current_zoom]


func _physics_process(delta: float) -> void:
	
	if Input.is_action_pressed("left"):
		next_camera_position.x -= planar_increment
	if Input.is_action_pressed("right"):
		next_camera_position.x += planar_increment
	if Input.is_action_pressed("down"):
		next_camera_position.y -= planar_increment
	if Input.is_action_pressed("up"):
		next_camera_position.y += planar_increment
		
	next_camera_position.x = clampf(next_camera_position.x, -game.size, game.size)
	next_camera_position.y = clampf(next_camera_position.y, -game.size, game.size)
	
	var direction: Vector3 = (next_camera_position - global_position)
	if direction.length() > EPSILON:
		global_position += direction * 0.5
	else:
		global_position = next_camera_position
		
func _raycast() -> void:
	var space_state = get_world_3d().direct_space_state
	var target_position = Plane(Vector3.BACK, Vector3(0, 0, -game.size / 2)).intersects_ray(global_position, project_ray_normal(get_viewport().get_mouse_position()))
	var collision_mask: int = 4 # i.e. only objects
	var query = PhysicsRayQueryParameters3D.create(global_position, target_position, collision_mask)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result = space_state.intersect_ray(query)
	var collider = result.get("collider")
	if collider is Area3D:
		selected = collider.get_parent()
	else:
		selected = collider

func _ready() -> void:
	global_position = Vector3(0, 0, 10)
	next_camera_position = global_position
	
	stream_player = AudioStreamPlayer.new()
	add_child(stream_player)
	stream_player.stream = strike_sound
