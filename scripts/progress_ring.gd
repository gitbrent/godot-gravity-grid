@tool
extends Control

@export var radius: float = 30.0:
	set(value): radius = value; queue_redraw()
	
@export var thickness: float = 6.0:
	set(value): thickness = value; queue_redraw()

@export var bg_color: Color = Color(0.2, 0.2, 0.2, 1.0):
	set(value): bg_color = value; queue_redraw()
	
@export var progress_color: Color = Color(0.2, 0.8, 1.0, 1.0):
	set(value): progress_color = value; queue_redraw()

# Progress is 0.0 to 1.0
var current_progress: float = 0.0

func set_progress(value: float) -> void:
	current_progress = clamp(value, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var center = size / 2.0
	
	# 1. Draw Background Ring (Full Circle)
	draw_arc(center, radius, 0, TAU, 64, bg_color, thickness, true)
	
	# 2. Draw Progress Ring
	# -TAU/4 rotates it so 0 starts at the top (12 o'clock)
	var end_angle = (current_progress * TAU) - (TAU / 4)
	var start_angle = -TAU / 4
	
	if current_progress > 0:
		draw_arc(center, radius, start_angle, end_angle, 64, progress_color, thickness, true)
