extends Node2D

# --- ONREADY VARS ---
@onready var board_layer: TileMapLayer = $GameWorld/BoardLayer
@onready var piece: Node2D = $GameWorld/ActivePiece
@onready var timer: Timer = $GameWorld/GravityTimer
@onready var main_menu: Control = $UI/MainMenu
@onready var start_button: Button = $UI/MainMenu/CenterContainer/VBoxContainer/StartButton
@onready var game_world: Node2D = $GameWorld
@onready var game_placeholder: Control = $UI/HUD/HBoxContainer/GamePlaceholder
@onready var next_piece_preview: Control = $UI/HUD/HBoxContainer/RightStats/CenterContainer/NextPiecePreview
@onready var hold_piece_preview: Control = $UI/HUD/HBoxContainer/LeftStats/VBoxContainer/CenterContainer/HoldPiecePreview
@onready var score_label: Label = $UI/HUD/HBoxContainer/LeftStats/VBoxContainer/ScoreLabel
@onready var level_label: Label = $UI/HUD/HBoxContainer/LeftStats/VBoxContainer/LevelLabel
@onready var lines_label: Label = $UI/HUD/HBoxContainer/LeftStats/VBoxContainer/LinesLabel
@onready var game_over_menu: Control = $UI/GameOverMenu
@onready var final_score_label: Label = $UI/GameOverMenu/CenterContainer/VBoxContainer/FinalScoreLabel
@onready var restart_button: Button = $UI/GameOverMenu/CenterContainer/VBoxContainer/RestartButton
# --- CONST VARS ---
const BLOCK_TEXTURE = preload("res://assets/block_bevel.tres")
const CELL_SIZE = 32
const GRID_WIDTH = 10 * CELL_SIZE
const FLOOR_Y = 19 * CELL_SIZE
# --- DATA [ENUMS] ---
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
# --- VARS ---
var current_shape_key: String = ""
var next_shape_key: String = ""
var hold_shape_key: String = ""
var can_hold: bool = true
# --- GAME STATE ---
var score: int = 0
var current_level: int = 1
var lines_cleared_total: int = 0

func _ready() -> void:
	main_menu.show()
	start_button.pressed.connect(_on_start_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	timer.timeout.connect(_on_gravity_tick)
	randomize()
	next_shape_key = TETROMINOES.keys().pick_random()
	
	# Initial Update of UI
	game_over_menu.hide()
	update_next_piece_ui()

func _on_start_pressed() -> void:
	# 1.
	start_button.hide()
	board_layer.clear()
	# 2. Reset State
	score = 0
	current_level = 1
	lines_cleared_total = 0
	timer.wait_time = 0.5 # Reset speed
	update_ui()
	# 3.  
	spawn_piece_from_next()

func spawn_piece_from_next() -> void:
	# promote Next to Current
	current_shape_key = next_shape_key
	next_shape_key = TETROMINOES.keys().pick_random()
	update_next_piece_ui()
	
	spawn_current_shape()

func spawn_current_shape() -> void:
	# 1. CLEANUP: Remove any existing blocks from the container!
	# (This is the missing magic part)
	for child in piece.get_children():
		child.queue_free()
	
	# 2. Allow holding again for the new turn
	can_hold = true
	
	# 3. Reset position to start
	piece.position = Vector2(4 * CELL_SIZE, 0)
	
	# 4. Create blocks
	var shape_data = TETROMINOES[current_shape_key]
	var shape_color = COLORS[current_shape_key]
	
	for grid_pos in shape_data:
		var block = Sprite2D.new()
		block.texture = BLOCK_TEXTURE
		block.modulate = shape_color
		block.position = Vector2(grid_pos.x * CELL_SIZE + (CELL_SIZE/2.0), grid_pos.y * CELL_SIZE + (CELL_SIZE/2.0))
		piece.add_child(block)
		
	# 5. Game Over Check
	if not move_piece(Vector2.ZERO):
		game_over()
	else:
		timer.start()

func update_next_piece_ui() -> void:
	var data = TETROMINOES[next_shape_key]
	var color = COLORS[next_shape_key]
	next_piece_preview.update_preview(data, color, next_shape_key)

func hold_piece() -> void:
	if not can_hold:
		return
		
	# 1. Clear current piece from board (visually)
	for child in piece.get_children():
		child.queue_free()
		
	# 2. The Swap Logic
	if hold_shape_key == "":
		# Case A: First hold (Hold is empty)
		hold_shape_key = current_shape_key
		spawn_piece_from_next()
	else:
		# Case B: Swap (Hold has a piece)
		var temp = current_shape_key
		current_shape_key = hold_shape_key
		hold_shape_key = temp
		
		# Respawn the 'new' current piece (which was the held one)
		spawn_current_shape() 
		
	# 3. Lock hold until next turn
	can_hold = false
	
	# 4. Update UI
	var data = TETROMINOES[hold_shape_key]
	var color = COLORS[hold_shape_key]
	hold_piece_preview.update_preview(data, color, hold_shape_key)

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
	elif event.is_action_pressed("hold_piece"): hold_piece()

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
	spawn_piece_from_next()

func check_lines() -> void:
	var lines_cleared_this_turn = 0
	
	var row = 19
	while row >= 0:
		if is_row_full(row):
			delete_row(row)
			shift_rows_down(row)
			lines_cleared_this_turn += 1
			# Note: We stay on 'row' index to check the new line that dropped in
		else:
			row -= 1
			
	# If we cleared anything, award points!
	if lines_cleared_this_turn > 0:
		add_score(lines_cleared_this_turn)

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

func add_score(lines_count: int) -> void:
	# Standard Arcade Scoring Rules
	var base_points = 0
	match lines_count:
		1: base_points = 100
		2: base_points = 300
		3: base_points = 500
		4: base_points = 800
	
	# Score scales with Level
	score += base_points * current_level
	
	# Update Stats
	lines_cleared_total += lines_count
	check_level_up()
	update_ui()

func check_level_up() -> void:
	# Level up every 10 lines
	@warning_ignore("integer_division")
	var new_level = 1 + (lines_cleared_total / 10)
	
	if new_level > current_level:
		current_level = new_level
		increase_speed()
		print("Level Up! Welcome to Level ", current_level)

func increase_speed() -> void:
	# Decrease timer wait time (make it faster)
	# Curve: Starts at 0.5s, decreases by 0.05s per level, caps at 0.05s
	var new_wait_time = max(0.05, 0.5 - ((current_level - 1) * 0.05))
	timer.wait_time = new_wait_time

func update_ui() -> void:
	score_label.text = str(score)
	level_label.text = str(current_level)
	lines_label.text = str(lines_cleared_total)

func game_over() -> void:
	print("Game Over!")
	timer.stop()
	
	# Show the menu
	final_score_label.text = "Final Score: " + str(score)
	game_over_menu.show()

func _on_restart_pressed() -> void:
	game_over_menu.hide()
	_on_start_pressed() # Reuse your existing start logic!
