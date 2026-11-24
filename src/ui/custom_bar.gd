class_name CustomBar
extends TextureProgressBar

func update(current_value: float, text = null) -> void:
	value = current_value
	if text != null:
		%Label.text = text
