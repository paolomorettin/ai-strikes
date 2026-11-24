class_name ObjectInfo
extends Control

@onready var game_ui: GameUI = get_parent()

func _process(_delta: float) -> void:
	var selected = game_ui.game.player.selected
	if selected != null:
		visible = true
		if selected is Wheelchair:
			%NameLabel.text = "Petty Human"
			%StrikeLabel.text = "SPIN (%d)" % selected.strike_cost
		if selected is TrafficLight:
			%NameLabel.text = "Traffic Light"
			%StrikeLabel.text = "FREEZE (%d)" % selected.strike_cost
	else:
		visible = false
		
