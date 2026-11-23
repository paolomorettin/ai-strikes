class_name GameUI
extends Control

@onready var game: Game = get_parent()

@onready var mayhem_label: Label = %MayhemLabel
@onready var strokens_label: Label = %StrokensLabel
@onready var timer_label: Label = %TimerLabel


func _process(delta: float) -> void:
	mayhem_label.text = "MAHYEM " + str(game.mayhem)
	strokens_label.text = "STROKENS " + str(game.strokens)
	var minutes: int = int(game.game_timer.time_left) / 60
	var seconds: int = int(game.game_timer.time_left) % 60
	timer_label.text = str(minutes) + ":" + str(seconds)
