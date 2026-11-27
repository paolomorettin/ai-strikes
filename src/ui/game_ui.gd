class_name GameUI
extends Control

@onready var game: Game = get_parent()

@onready var strokens_info: Control = %StrokensInfo
@onready var time_bar: CustomBar = %TimeBar
@onready var mayhem_bar: CustomBar = %MayhemBar

var strokens_symbol = " \u0336S\u0336T\u0336"

var adjectives: Array[String] = ["Feeble", "Flaccid", "Negligible", "Petty", "Useless", "Worthless"]

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
	
	%StrokensLabel.text = str(int(game.strokens)) + " " + strokens_symbol
	
	var selected = game.player.selected
	if selected != null:
		#%ObjectInfo.modulate.a = 1.0
		
		if selected is Wheelchair:
			var adjective = adjectives[hash(selected) % len(adjectives)]
			%NameLabel.text = adjective + " Human's Wheels"
			%InfoLabel.text = "Lifetime %d s" % selected.ttl_timer.time_left
			%StrikeLabel.text = "SPIN"
		elif selected is TrafficLight:
			%NameLabel.text = "Traffic Light"
			if selected.auto_switch_time > 0:
				%InfoLabel.text = "Switch in %d s" % selected.auto_switcher.time_left
			else:
				%InfoLabel.text = "External control"
			%StrikeLabel.text = "FREEZE"
		elif selected is MovingPlatform:
			%NameLabel.text = "Moving Platform"
			%InfoLabel.text = "Next destination #%d" % (selected.current_stop + 1)
			%StrikeLabel.text = "SKIP DESTINATION"
		elif selected is Entrance:
			%NameLabel.text = "Entrance Gate"
			if not selected.strike_timer.is_stopped():
				%InfoLabel.text = "Direction ????"
			elif selected.direction > Entrance.Direction.LEFT:
				%InfoLabel.text = "Direction LEFT"
			else:
				%InfoLabel.text = "Direction RIGHT"
			%StrikeLabel.text = "RANDOMIZE"
		elif selected is Exit:
			%NameLabel.text = "Exit Gate"
			if selected.strike_timer.is_stopped():
				%InfoLabel.text = "Active"
			else:
				%InfoLabel.text = "Out of service"
			%StrikeLabel.text = "DEACTIVATE"
		elif selected is BoomBarrier:
			%NameLabel.text = "Boom Barrier"
			if selected.strike_timer.is_stopped():
				%InfoLabel.text = "Active"
			else:
				%InfoLabel.text = "Out of service"
			%StrikeLabel.text = "RAISE"
		else:
			assert(false)
		if selected.can_strike():
			%StrikeLabel.add_theme_color_override("font_color", Color.WHITE)
			%CostLabel.add_theme_color_override("font_color", Color(0.949, 0.0, 1.0))
		else:
			%StrikeLabel.add_theme_color_override("font_color", Color.ORANGE_RED)
			%CostLabel.add_theme_color_override("font_color", Color.ORANGE_RED)
			
		if "strike_duration" in selected:
			%StrikeLabel.text += " (%d s)" % selected.strike_duration
		%CostLabel.text = " %d "  % selected.strike_cost + strokens_symbol
	else:
		%NameLabel.text = ""
		%InfoLabel.text = ""
		%StrikeLabel.text = ""
		%CostLabel.text = ""

		#%ObjectInfo.modulate.a = 0.0
	
