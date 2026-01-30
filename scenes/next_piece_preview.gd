extends Control

const PREVIEW_SCALE = 0.6
const CELL_SIZE = 32 * PREVIEW_SCALE
const BLOCK_TEXTURE = preload("res://assets/block_bevel.tres")

func update_preview(shape_data: Array, color: Color, shape_key: String) -> void:
	# Clear previous drawing
	queue_redraw()
	
	# Store data for _draw
	set_meta("shape", shape_data)
	set_meta("color", color)
	set_meta("key", shape_key)

func _draw() -> void:
	if not has_meta("shape"): return
	
	var shape = get_meta("shape")
	var color = get_meta("color")
	var key = get_meta("key")
	
	var center_offset = get_size() / 2
	
	# Adjust offsets based on shape to center them visually
	var shape_offset = Vector2.ZERO
	if key == "I": shape_offset = Vector2(-0.5, -0.5) * CELL_SIZE
	elif key == "O": shape_offset = Vector2(-0.5, -0.5) * CELL_SIZE
	
	for grid_pos in shape:
		var draw_pos = center_offset + (Vector2(grid_pos) * CELL_SIZE) + shape_offset
		var rect = Rect2(draw_pos, Vector2(CELL_SIZE, CELL_SIZE))
		
		# Draw the texture with tint
		draw_texture_rect(BLOCK_TEXTURE, rect, false, color)
