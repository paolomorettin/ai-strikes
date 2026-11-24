class_name GameUI
extends Control

@onready var game: Game = get_parent()

@onready var mayhem_label: Label = %MayhemLabel
@onready var strokens_label: Label = %StrokensLabel
@onready var timer_label: Label = %TimerLabel

func tilt_label(label: Label) -> void:
	var n_shakes: int = 5
	var duration: float = 0.5 # s
	var tween: Tween = get_tree().create_tween()
	var initial_intensity = 15.0
	var final_intensity = 2.0
	label.pivot_offset = label.size / 2.0
	for i in range(n_shakes):
		var intensity = initial_intensity - i * (initial_intensity - final_intensity) / n_shakes
		var target_rotation = deg_to_rad(intensity * (2 * (i % 2) - 1))
		tween.tween_property(label, "rotation", target_rotation, duration / n_shakes)
		
	tween.tween_callback(func (): label.rotation = 0)
	

func _process(delta: float) -> void:
	# update stats
	mayhem_label.text = "MAHYEM " + str(game.mayhem)
	strokens_label.text = "STROKENS %05d" % int(game.strokens)
	var minutes: int = int(game.game_timer.time_left) / 60
	var seconds: int = int(game.game_timer.time_left) % 60
	timer_label.text = ("%02d" % minutes) + ":" + ("%02d" % seconds)
	
