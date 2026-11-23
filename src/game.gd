class_name Game
extends Node3D

@export var game_time: float = 300.0
@export var initial_strokens: int = 0
@export var player: Player

var game_timer: Timer
var game_ui: GameUI

var mayhem: int = 0
var strokens: int = initial_strokens

func game_over() -> void:
	queue_free()

func _ready() -> void:
	if player == null:
		player = preload("res://src/player.tscn").instantiate()
		add_child(player)
	
	game_timer = Timer.new()
	add_child(game_timer)
	game_timer.one_shot = true
	game_timer.wait_time = game_time
	game_timer.timeout.connect(game_over)
	game_timer.start()
	
	game_ui = preload("res://src/ui/game_ui.tscn").instantiate()
	add_child(game_ui)
