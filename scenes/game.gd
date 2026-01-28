extends Node2D

const CELL_SIZE = 32
const GRID_WIDTH = 10 * CELL_SIZE
const FLOOR_Y = 19 * CELL_SIZE
var current_shape_key: String = ""

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
	"I": Color.CYAN, "O": Color.YELLOW, "T": Color.PURPLE, 
	"S": Color.GREEN, "Z": Color.RED, "J": Color.BLUE, "L": Color.ORANGE
}

@onready var piece: Node2D = $ActivePiece
@onready var timer: Timer = $GravityTimer
@onready var btn: Button = $StartButton

func _ready() -> void:
	btn.pressed.connect(_on_start_pressed)
	timer.timeout.connect(_on_gravity_tick)
	btn.text = "START GAME"

func _on_start_pressed() -> void:
	btn.hide()
	spawn_piece()

func spawn_piece() -> void:
	for child in piece.get_children():
		child.queue_free()
	
	var keys = TETROMINOES.keys()

	# 1. Pick a random shape
	current_shape_key = keys.pick_random()
	var shape_data = TETROMINOES[current_shape_key]
	var shape_color = COLORS[current_shape_key]
	
	# 2. Clear old blocks from the container
	for child in piece.get_children():
		child.queue_free()
	
	# 3. Create the 4 blocks
	for grid_pos in shape_data:
		var block = ColorRect.new()
		block.size = Vector2(CELL_SIZE, CELL_SIZE)
		block.color = shape_color
		# Important: Position the block relative to the container
		block.position = Vector2(grid_pos.x * CELL_SIZE, grid_pos.y * CELL_SIZE)
		piece.add_child(block)
	
	# 4. Position the container at the top center
	piece.position = Vector2(4 * CELL_SIZE, 0)
	timer.start()

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

func move_piece(dir: Vector2) -> void:
	var target_pos = piece.position + (dir * CELL_SIZE)
	
	# COLLISION CHECK: Loop through every block in the piece
	for block in piece.get_children():
		# Calculate where this specific block would be in Global/Board space
		var block_global_pos = target_pos + block.position
		
		# Check Walls
		if block_global_pos.x < 0 or block_global_pos.x >= GRID_WIDTH:
			return # Hit wall
		
		# Check Floor
		if block_global_pos.y >= FLOOR_Y:
			if dir == Vector2.DOWN:
				lock_piece()
			return # Hit floor
			
	# If loop finishes with no returns, the move is valid
	piece.position = target_pos

func lock_piece() -> void:
	print("Locked!")
	timer.stop()
	btn.text = "RESTART"
	btn.show()
