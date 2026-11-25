extends Game

var exploding_wheelchair: Wheelchair
var wheelchairs: Array

func _physics_process(delta: float) -> void:
	for c in wheelchairs:
		if is_instance_valid(c[0]):
			c[0].global_position = c[1]
			
func reset() -> void:
	wheelchairs = []
	
	for x_pos in [-3, -1, 2, 6]:
		var wheelchair: Wheelchair = preload("res://src/wheelchair.tscn").instantiate()
		%Level.add_child(wheelchair)
		wheelchair.global_position = Vector3(x_pos, 0.0, 0.0)
		wheelchairs.append([wheelchair, wheelchair.global_position])
		
	exploding_wheelchair = wheelchairs[0][0]

func _ready() -> void:
	super._ready()
	
	game_ui.hide()
	%Label.text = str(Wheelchair.explosion_radius)
	
	%ExplosionButton.pressed.connect(
		func():
			Wheelchair.explosion_radius = float(%Label.text)
			exploding_wheelchair.die()
	)
	
	%ResetButton.pressed.connect(reset)

	reset()
	Wheelchair.explosion_speed = 0.5
