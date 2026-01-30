extends Node2D

const BLOCK_TEXTURE = preload("res://assets/block_bevel.tres")
const CELL_SIZE = 32
const GRID_WIDTH = 10 * CELL_SIZE
const FLOOR_Y = 19 * CELL_SIZE
var current_shape_key: String = ""
var next_shape_key: String = ""

# --- DATA ---
const TETROMINOES = {
	"I": [Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	"O": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	"T": [Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
	"S": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(0, 0)],
	"Z": [Vector2i(-1, 1), Vector2i(0, 1), Vector2i(0, 0), Vector2i(1, 0)],
	"J": [Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)],
	"L": [Vector2i(1, -1), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)]
}
const COLORS = {
	"I": Color.CYAN, "O": Color.YELLOW, "T": Color.PURPLE, "S": Color.GREEN, "Z": Color.RED, "J": Color.BLUE, "L": Color.ORANGE
}
const TILE_IDS = {
	"I": 1, "O": 2, "T": 3, "S": 4, "Z": 5, "J": 6, "L": 7
}

@onready var piece: Node2D = $GameWorld/ActivePiece
@onready var board_layer: TileMapLayer = $GameWorld/BoardLayer
@onready var timer: Timer = $GameWorld/GravityTimer
@onready var start_button: Button = $UI/MainMenu/CenterContainer/VBoxContainer/StartButton
@onready var game_world: Node2D = $GameWorld
@onready var game_placeholder: Control = $UI/HUD/HBoxContainer/GamePlaceholder
@onready var next_piece_preview: Control = $UI/HUD/HBoxContainer/RightStats/CenterContainer/NextPiecePreview

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	timer.timeout.connect(_on_gravity_tick)
	randomize()
	next_shape_key = TETROMINOES.keys().pick_random()
	
	# Initial Update of UI
	update_next_piece_ui()

func _on_start_pressed() -> void:
	start_button.hide()
	board_layer.clear()
	spawn_piece()

func spawn_piece() -> void:
	# 1. Clean up old piece
	for child in piece.get_children():
		child.queue_free()
	
	# 2. Promote "Next" to "Current"
	current_shape_key = next_shape_key
	
	# 3. Pick a NEW "Next"
	next_shape_key = TETROMINOES.keys().pick_random()
	
	# 4. Update the UI to show the NEW next piece
	update_next_piece_ui()
	
	# 5. Center piece
	piece.position = Vector2(4 * CELL_SIZE, 0)
	
	var shape_data = TETROMINOES[current_shape_key]
	var shape_color = COLORS[current_shape_key]
	
	# Create the 4 blocks
	for grid_pos in shape_data:
		# CHANGE: Use Sprite2D instead of ColorRect
		var block = Sprite2D.new()
		block.texture = BLOCK_TEXTURE
		
		# COLOR: Modulate tints the white texture
		block.modulate = shape_color 
		
		block.position = Vector2(grid_pos.x * CELL_SIZE + (CELL_SIZE/2.0), grid_pos.y * CELL_SIZE + (CELL_SIZE/2.0))
		# Note: Sprites are centered by default! 
		# We added +CELL_SIZE/2 to position because ColorRect was Top-Left based.
		
		piece.add_child(block)
		
	# GAME OVER CHECK
	# Pass Vector2.ZERO to check "Can I exist where I just spawned?"
	# If move_piece returns FALSE (it failed), that means we spawned inside a block.
	if not move_piece(Vector2.ZERO):
		print("Game Over!")
		timer.stop()
		# TODO: Show 'Game Over' UI here later
	else:
		timer.start()

func update_next_piece_ui() -> void:
	var data = TETROMINOES[next_shape_key]
	var color = COLORS[next_shape_key]
	next_piece_preview.update_preview(data, color, next_shape_key)

func rotate_piece() -> void:
	# 1. The "O" piece (Square) never rotates
	if current_shape_key == "O":
		return

	# 2. Calculate new positions for all child blocks
	var new_positions = []
	for block in piece.get_children():
		# Get local position relative to the pivot (ActivePiece center)
		var old_pos = block.position
		
		# 90-degree clockwise rotation formula for Godot (Y is down)
		# x' = -y
		# y' = x
		var new_x = -old_pos.y
		var new_y = old_pos.x
		new_positions.append(Vector2(new_x, new_y))

	# 3. Validation Check
	# We must check if these new local positions + the global piece offset are valid
	for local_pos in new_positions:
		var global_pos = piece.position + local_pos
		
		# Wall Checks
		if global_pos.x < 0 or global_pos.x >= GRID_WIDTH:
			return # Wall Kick could go here later, for now just block it
		
		# Floor Check
		if global_pos.y >= FLOOR_Y:
			return 
			
	# 4. Commit the Rotation
	var i = 0
	for block in piece.get_children():
		block.position = new_positions[i]
		i += 1

func _unhandled_input(event: InputEvent) -> void:
	if timer.is_stopped(): return
	
	if event.is_action_pressed("ui_left"): move_piece(Vector2.LEFT)
	elif event.is_action_pressed("ui_right"): move_piece(Vector2.RIGHT)
	elif event.is_action_pressed("ui_down"): move_piece(Vector2.DOWN)
	elif event.is_action_pressed("ui_up"): rotate_piece()

func _on_gravity_tick() -> void:
	move_piece(Vector2.DOWN)

func move_piece(dir: Vector2) -> bool:
	var target_pos = piece.position + (dir * CELL_SIZE)
	
	for block in piece.get_children():
		var block_global_pos = target_pos + block.position
		#var block_relative_pos = target_pos + block.position
		
		# 1. Wall Checks
		if block_global_pos.x < 0 or block_global_pos.x >= GRID_WIDTH:
			#print("Fail: Hit Wall at X=", block_relative_pos.x)
			return false # Hit wall -> Move Failed
		
		# 2. Floor Check
		if block_global_pos.y >= FLOOR_Y:
			if dir == Vector2.DOWN:
				lock_piece()
			#print("Fail: Hit Floor at Y=", block_relative_pos.y)
			return false # Hit floor -> Move Failed
			
		# 3. BOARD COLLISION
		# Convert pixel position to grid coordinates (Vector2i)
		var grid_pos = board_layer.local_to_map(block_global_pos)
		# Check if a tile exists at this coordinate (source_id != -1)
		var tile_id = board_layer.get_cell_source_id(grid_pos)
		if tile_id != -1:
			#print("Fail: Hit Board Tile at ", grid_pos, " ID: ", tile_id)
			if dir == Vector2.DOWN:
				lock_piece()
			return false # Hit another block -> Move Failed
			
	# LAST: If we made it here, the move is valid!
	piece.position = target_pos
	return true # Move Succeeded

func lock_piece() -> void:
	var tile_id = TILE_IDS[current_shape_key]
	
	# 1. Get the correct Source ID dynamically
	# (This grabs the ID of the first source in the list)
	var source_id = board_layer.tile_set.get_source_id(0)

	for block in piece.get_children():
		var global_pos = piece.position + block.position
		var grid_pos = board_layer.local_to_map(global_pos)
		
		# Set cell using source_id 0, coord (0,0), and the alternative_tile ID
		board_layer.set_cell(grid_pos, source_id, Vector2i(0, 0), tile_id)
		
	# 2. Check for Lines
	check_lines() 
	
	# 3. Spawn the next piece
	spawn_piece()

func check_lines() -> void:
	# Loop from bottom (row 19) up to top (row 0)
	var row = 19
	while row >= 0:
		if is_row_full(row):
			delete_row(row)
			# shift_rows_down(row) is implicit because we stay on this 'row' index
			# and check it again (since the row above just dropped into it)
			shift_rows_down(row)
		else:
			row -= 1

func is_row_full(y: int) -> bool:
	for x in range(10): # Columns 0 to 9
		if board_layer.get_cell_source_id(Vector2i(x, y)) == -1:
			return false # Found an empty spot
	return true # No empty spots found

func delete_row(y: int) -> void:
	# Clear the line visually
	for x in range(10):
		board_layer.set_cell(Vector2i(x, y), -1)

func shift_rows_down(empty_row_y: int) -> void:
	# Go from the empty row UP to the top
	for y in range(empty_row_y, 0, -1):
		for x in range(10):
			# Get the cell from the row ABOVE
			var source_id = board_layer.get_cell_source_id(Vector2i(x, y - 1))
			var atlas_coords = board_layer.get_cell_atlas_coords(Vector2i(x, y - 1))
			
			# Move it DOWN to the current row
			board_layer.set_cell(Vector2i(x, y), source_id, atlas_coords)
			
			# Clear the row above (it has moved down)
			board_layer.set_cell(Vector2i(x, y - 1), -1)
