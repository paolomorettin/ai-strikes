extends Node3D

@onready var tl: TrafficLight = %TL
@onready var tl_timer: Timer = %TLTimer

func _ready() -> void:
	tl_timer.timeout.connect(tl.switch)
	tl_timer.start()
