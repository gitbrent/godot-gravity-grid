extends Node2D

@export var grid_size: Vector2i = Vector2i(10, 20)
@export var cell_size: int = 32
@export var grid_color: Color = Color(1, 1, 1, 0.1) # Faint white

func _draw() -> void:
	# Draw Vertical Lines
	for x in range(grid_size.x + 1):
		var start = Vector2(x * cell_size, 0)
		var end = Vector2(x * cell_size, grid_size.y * cell_size)
		draw_line(start, end, grid_color, 1.0)
		
	# Draw Horizontal Lines
	for y in range(grid_size.y + 1):
		var start = Vector2(0, y * cell_size)
		var end = Vector2(grid_size.x * cell_size, y * cell_size)
		draw_line(start, end, grid_color, 1.0)

func _ready() -> void:
	queue_redraw()
