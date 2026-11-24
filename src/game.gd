class_name Game
extends Node3D

static var size: float = 100.0 # m

@export var player: Player

@export var startup_delay: float = 2.0 # s

@export var initial_time: float = 300.0 # s
@export var initial_strokens: float = 100
@export var strokens_per_second: float = 1.0 # 1/s


var game_timer: Timer
var strokens_timer: Timer
var game_ui: GameUI

var mayhem: int = 0
var strokens: float = initial_strokens

func game_over() -> void:
	queue_free()

func _ready() -> void:
	if player == null:
		player = preload("res://src/player.tscn").instantiate()
		add_child(player)
	
	game_timer = Timer.new()
	add_child(game_timer)
	game_timer.one_shot = true
	game_timer.wait_time = initial_time
	game_timer.timeout.connect(game_over)
	#game_timer.start()
	
	strokens_timer = Timer.new()
	add_child(strokens_timer)
	strokens_timer.one_shot = false
	strokens_timer.wait_time = 1.0 / strokens_per_second
	strokens_timer.timeout.connect(func (): strokens += 1)
	#strokens_timer.start()
	
	game_ui = preload("res://src/ui/game_ui.tscn").instantiate()
	add_child(game_ui)
	
	var initial_timer = get_tree().create_timer(startup_delay)
	initial_timer.timeout.connect(
		func(): 
			game_timer.start()
			strokens_timer.start()
	)
