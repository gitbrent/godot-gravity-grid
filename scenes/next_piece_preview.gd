extends Control

# SCALE: 0.8 fits a 4-block "I" piece comfortably inside a 128px panel.
# Set to 1.0 if you want them to match the board exactly (but watch for clipping!)
const PREVIEW_SCALE = 0.8
const BASE_CELL_SIZE = 32
const DRAW_CELL_SIZE = BASE_CELL_SIZE * PREVIEW_SCALE
const BLOCK_TEXTURE = preload("res://assets/block_bevel.tres")

func update_preview(shape_data: Array, color: Color) -> void:
	# Clear previous drawing
	queue_redraw()
	
	# Store data for _draw
	set_meta("shape", shape_data)
	set_meta("color", color)

func _draw() -> void:
	if not has_meta("shape"): return
	
	var shape = get_meta("shape")
	var color = get_meta("color")
	
	# 1. Calculate the Bounding Box of the shape dynamically
	var min_x = 999
	var max_x = -999
	var min_y = 999
	var max_y = -999
	
	for grid_pos in shape:
		if grid_pos.x < min_x: min_x = grid_pos.x
		if grid_pos.x > max_x: max_x = grid_pos.x
		if grid_pos.y < min_y: min_y = grid_pos.y
		if grid_pos.y > max_y: max_y = grid_pos.y
		
	# 2. Calculate pixel dimensions
	# (+1 because a block at index 0 has a width of 1)
	var width_px = (max_x - min_x + 1) * DRAW_CELL_SIZE
	var height_px = (max_y - min_y + 1) * DRAW_CELL_SIZE
	
	# 3. Calculate Center Offset
	# We align the center of the Shape's Bounding Box to the Control's Center
	var control_center = get_size() / 2
	
	# The top-left of the bounds (relative to the pivot 0,0)
	var bounds_top_left = Vector2(min_x, min_y) * DRAW_CELL_SIZE
	
	# The actual center of the shape logic
	var shape_center_offset = bounds_top_left + Vector2(width_px, height_px) / 2.0
	
	# The final draw offset
	var final_offset = control_center - shape_center_offset
	
	# 4. Draw
	for grid_pos in shape:
		var draw_pos = (Vector2(grid_pos) * DRAW_CELL_SIZE) + final_offset
		var rect = Rect2(draw_pos, Vector2(DRAW_CELL_SIZE, DRAW_CELL_SIZE))
		
		draw_texture_rect(BLOCK_TEXTURE, rect, false, color)
