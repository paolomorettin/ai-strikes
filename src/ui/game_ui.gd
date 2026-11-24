class_name GameUI
extends Control

@onready var game: Game = get_parent()

@onready var strokens_info: Control = %StrokensInfo
@onready var time_bar: CustomBar = %TimeBar
@onready var mayhem_bar: CustomBar = %MayhemBar

func tilt_control(control: Control) -> void:
	var n_shakes: int = 5
	var duration: float = 0.5 # s
	var tween: Tween = get_tree().create_tween()
	var initial_intensity = 15.0
	var final_intensity = 2.0
	control.pivot_offset = control.size / 2.0
	for i in range(n_shakes):
		var intensity = initial_intensity - i * (initial_intensity - final_intensity) / n_shakes
		var target_rotation = deg_to_rad(intensity * (2 * (i % 2) - 1))
		tween.tween_property(control, "rotation", target_rotation, duration / n_shakes)
		
	tween.tween_callback(func (): control.rotation = 0)
	

func _process(_delta: float) -> void:
	# update stats
	mayhem_bar.update(game.mayhem / game.max_mayhem)
	time_bar.update(game.game_timer.time_left / game.initial_time)

	#var minutes: int = int(game.game_timer.time_left) / 60
	#var seconds: int = int(game.game_timer.time_left) % 60
	#timer_label.text = ("%02d" % minutes) + ":" + ("%02d" % seconds)
	
	%StrokensLabel.text = str(int(game.strokens))
	
	var selected = game.player.selected
	if selected != null:
		%ObjectInfo.modulate.a = 1.0
		
		if selected is Wheelchair:
			%NameLabel.text = "Petty Human"
			%StrikeLabel.text = "SPIN (%d)" % selected.strike_cost
		if selected is TrafficLight:
			%NameLabel.text = "Traffic Light"
			%StrikeLabel.text = "FREEZE (%d)" % selected.strike_cost
	else:
		%ObjectInfo.modulate.a = 0.0
	
