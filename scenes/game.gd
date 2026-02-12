extends Node2D

# --- ONREADY VARS ---
@onready var board_layer: TileMapLayer = $GameWorld/BoardLayer
@onready var piece: Node2D = $GameWorld/ActivePiece
@onready var timer: Timer = $GameWorld/GravityTimer
@onready var main_menu: Control = $UI/MainMenu
@onready var start_button: Button = $UI/MainMenu/CenterContainer/StartButton
@onready var game_world: Node2D = $GameWorld
@onready var game_placeholder: Control = $UI/HUD/HBoxContainer/GamePlaceholder
@onready var next_piece_preview: Control = $UI/HUD/HBoxContainer/RightStats/NextContainer/CenterContainer/NextPiecePreview
@onready var hold_piece_preview: Control = $UI/HUD/HBoxContainer/LeftStats/HoldContainer/CenterContainer/HoldPiecePreview
@onready var level_label: Label = $UI/HUD/HBoxContainer/LeftStats/StatsContainer/LevelLabel
@onready var score_label: Label = $UI/HUD/HBoxContainer/RightStats/StatsContainer/ScoreLabel
@onready var lines_label: Label = $UI/HUD/HBoxContainer/RightStats/StatsContainer/LinesLabel
@onready var game_over_menu: Control = $UI/GameOverMenu
@onready var final_score_label: Label = $UI/GameOverMenu/CenterContainer/VBoxContainer/FinalScoreLabel
@onready var restart_button: TextureButton = $UI/GameOverMenu/CenterContainer/VBoxContainer/RestartButton
@onready var sound_manager: Node = $SoundManager
@onready var ghost_piece: Node2D = $GameWorld/GhostPiece
# --- CONST VARS ---
const BLOCK_TEXTURE = preload("res://assets/block_bevel.tres")
const GHOST_TEXTURE = preload("res://assets/ghost_bevel.tres")
const CELL_SIZE = 32
const GRID_WIDTH = 10 * CELL_SIZE
const FLOOR_Y = 20 * CELL_SIZE
const DROP_SPEED_DELAY = 0.8 # Starts at 0.8s (Slow)
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
# --- DAS ---
# DAS SETTINGS
const DAS_DELAY = 0.2     # Time before auto-repeat starts
const DAS_SPEED = 0.05    # Time between auto-repeat moves
# DAS STATE
var das_timer: float = 0.0
var current_das_direction: Vector2 = Vector2.ZERO

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
	timer.wait_time = DROP_SPEED_DELAY
	update_ui()
	# 3.  
	spawn_piece_from_next()

func _process(delta: float) -> void:
	if timer.is_stopped() or current_das_direction == Vector2.ZERO:
		return

	# Accumulate time
	das_timer += delta
	
	# If we have held longer than the initial delay...
	if das_timer > DAS_DELAY:
		# Keep moving as long as we have "credit" in the timer
		while das_timer > DAS_DELAY + DAS_SPEED:
			das_timer -= DAS_SPEED # Pay the cost
			if move_piece(current_das_direction):
				sound_manager.play_move()

func spawn_piece_from_next() -> void:
	# promote Next to Current
	current_shape_key = next_shape_key
	next_shape_key = TETROMINOES.keys().pick_random()
	update_next_piece_ui()
	
	spawn_current_shape()

func spawn_current_shape() -> void:
	# 1. CLEANUP: Instantly detach old blocks so the Ghost doesn't see them
	for child in piece.get_children():
		piece.remove_child(child) # Removes from tree instantly
		child.queue_free()        # Kills it from memory later
	
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
	next_piece_preview.update_preview(data, color)

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
	hold_piece_preview.update_preview(data, color)

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
	
	# 5. Ghost piece
	update_ghost()
	
	# 6. SFX
	sound_manager.play_rotate()

func _unhandled_input(event: InputEvent) -> void:
	if timer.is_stopped(): return # Don't move if game over
	
	# 1. MOVEMENT (Left/Right)
	if event.is_action_pressed("ui_left"):
		current_das_direction = Vector2.LEFT
		das_timer = 0.0
		move_piece(Vector2.LEFT) # Instant move 1
		sound_manager.play_move()
		
	elif event.is_action_pressed("ui_right"):
		current_das_direction = Vector2.RIGHT
		das_timer = 0.0
		move_piece(Vector2.RIGHT) # Instant move 1
		sound_manager.play_move()
		
	elif event.is_action_released("ui_left") and current_das_direction == Vector2.LEFT:
		current_das_direction = Vector2.ZERO
		
	elif event.is_action_released("ui_right") and current_das_direction == Vector2.RIGHT:
		current_das_direction = Vector2.ZERO

	# 2. OTHER ACTIONS (Hard Drop, Rotate, Hold)
	elif event.is_action_pressed("ui_up"): 
		rotate_piece()
	elif event.is_action_pressed("hold_piece"): 
		hold_piece()
	elif event.is_action_pressed("ui_accept"): 
		hard_drop()
	elif event.is_action_pressed("ui_down"):
		# Soft Drop (Manual push down)
		move_piece(Vector2.DOWN)
		add_points(1) # Classic rule: 1 point per soft drop cell!

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
	# If move is valid (at the very end of the function)
	piece.position = target_pos
	update_ghost()
	if dir != Vector2.DOWN:
		sound_manager.play_move()
	return true # Move Succeeded

func hard_drop() -> void:
	# 1. Find the drop distance (Reuse ghost logic logic!)
	var drop_offset = Vector2.ZERO
	while is_position_valid(drop_offset + Vector2(0, CELL_SIZE)):
		drop_offset += Vector2(0, CELL_SIZE)
	
	# 2. Apply Move
	piece.position += drop_offset
	var cells_dropped = drop_offset.y / CELL_SIZE
	add_points(cells_dropped * 2)
	
	# 3. Lock instantly
	lock_piece()

func lock_piece() -> void:
	# 1. Kill the ghost instantly so it doesn't overlap the new tiles
	for child in ghost_piece.get_children():
		child.queue_free()
	
	# 2. Get the correct Source ID dynamically
	# (This grabs the ID of the first source in the list)
	var tile_id = TILE_IDS[current_shape_key]
	var source_id = board_layer.tile_set.get_source_id(0)
	for block in piece.get_children():
		var global_pos = piece.position + block.position
		var grid_pos = board_layer.local_to_map(global_pos)
		
		# Set cell using source_id 0, coord (0,0), and the alternative_tile ID
		board_layer.set_cell(grid_pos, source_id, Vector2i(0, 0), tile_id)
	
	# 2.
	sound_manager.play_lock()
	
	# 3. Check for Lines
	check_lines() 
	
	# 4. Spawn the next piece
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
		process_line_clears(lines_cleared_this_turn)
		sound_manager.play_clear()

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

func is_position_valid(test_offset: Vector2) -> bool:
	### Checks if the active piece WOULD be valid at a specific offset
	var test_pos = piece.position + test_offset
	
	for block in piece.get_children():
		var block_global_pos = test_pos + block.position
		var grid_pos = board_layer.local_to_map(block_global_pos)
		
		# 1. Wall Checks
		if block_global_pos.x < 0 or block_global_pos.x >= GRID_WIDTH:
			return false
		
		# 2. Floor Check
		if block_global_pos.y >= FLOOR_Y:
			return false
			
		# 3. Board Collision
		if board_layer.get_cell_source_id(grid_pos) != -1:
			return false
			
	return true

func update_ghost() -> void:
	# 1. Clear old ghost blocks
	for child in ghost_piece.get_children():
		child.queue_free()
		
	# 2. Create Ghost Blocks
	for block in piece.get_children():
		# 2.1: Instead of duplicate(), we create a new Sprite so we can change the texture
		var ghost_block = Sprite2D.new()
		ghost_block.texture = GHOST_TEXTURE
		ghost_block.position = block.position
		
		# 2.2: Let's tint it slightly to match the piece color, but keep it transparent
		ghost_block.modulate = block.modulate 
		#ghost_block.modulate.a = 0.5 # Force transparency logic here # NOTE: nah, dark colors are too washed out
		
		# 2.3: Add
		ghost_piece.add_child(ghost_block)
		
	# 3. Find Drop Position (Same as before)
	var drop_offset = Vector2.ZERO
	while is_position_valid(drop_offset + Vector2(0, CELL_SIZE)):
		drop_offset += Vector2(0, CELL_SIZE)
		
	# 4. Place Ghost
	ghost_piece.position = piece.position + drop_offset

func add_points(amount: int) -> void:
	score += amount
	update_ui()

func process_line_clears(lines_count: int) -> void:
	# 1. Update Totals
	lines_cleared_total += lines_count
	check_level_up()
	
	# 2. Calculate Score based on Tetris rules
	var base_points = 0
	match lines_count:
		1: base_points = 100
		2: base_points = 300
		3: base_points = 500
		4: base_points = 800
		
	# 3. Add the points
	add_points(base_points * current_level)

func check_level_up() -> void:
	# Level up every 10 lines
	@warning_ignore("integer_division")
	var new_level = 1 + (lines_cleared_total / 10)
	
	if new_level > current_level:
		current_level = new_level
		increase_speed()
		print("Level Up! Welcome to Level ", current_level)

func increase_speed() -> void:
	### Decrease timer wait time (make it faster)
	# Delat starts at DROP_SPEED_DELAY, decreases by 0.03s per level
	var new_wait_time = max(0.05, DROP_SPEED_DELAY - ((current_level - 1) * 0.03)) 
	timer.wait_time = new_wait_time

func update_ui() -> void:
	score_label.text = str(score)
	level_label.text = str(current_level)
	lines_label.text = str(lines_cleared_total)

func game_over() -> void:
	print("Game Over!")
	timer.stop()
	
	sound_manager.play_game_over()
	
	# Show the menu
	final_score_label.text = "Final Score: " + str(score)
	game_over_menu.show()

func _on_restart_pressed() -> void:
	game_over_menu.hide()
	_on_start_pressed() # Reuse your existing start logic!
