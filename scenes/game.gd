extends Node2D

# Config
const CELL_SIZE = 32
const GRID_WIDTH = 10 * CELL_SIZE  # 320 px
const FLOOR_Y = 19 * CELL_SIZE     # 608 px (Row 19)

# Nodes
@onready var piece: ColorRect = $ActivePiece
@onready var timer: Timer = $GravityTimer
@onready var btn: Button = $StartButton

func _ready() -> void:
	btn.pressed.connect(_on_start_pressed)
	timer.timeout.connect(_on_gravity_tick)
	
	# Initial Setup
	btn.text = "START GAME"

func _on_start_pressed() -> void:
	btn.hide()
	spawn_piece()

func spawn_piece() -> void:
	# Start at top-middle (approx column 4)
	piece.position = Vector2(4 * CELL_SIZE, 0)
	piece.show()
	piece.color = Color.CYAN
	timer.start()

# --- INPUT HANDLING ---
func _unhandled_input(event: InputEvent) -> void:
	# Only allow input if the game is running (timer is active)
	if timer.is_stopped():
		return
		
	if event.is_action_pressed("ui_left"):
		move_piece(Vector2.LEFT)
	elif event.is_action_pressed("ui_right"):
		move_piece(Vector2.RIGHT)
	elif event.is_action_pressed("ui_down"):
		move_piece(Vector2.DOWN)
	# Note: "ui_up" usually rotates, we'll add that later

# --- CORE MOVEMENT LOGIC ---
func _on_gravity_tick() -> void:
	move_piece(Vector2.DOWN)

func move_piece(dir: Vector2) -> void:
	# 1. Calculate the hypothetical new position
	var current_pos = piece.position
	var target_pos = current_pos + (dir * CELL_SIZE)
	
	# 2. Wall Checks (Left/Right limits)
	# The piece position is its Top-Left corner.
	# So valid X is 0 up to (Width - PieceWidth)
	if target_pos.x < 0 or target_pos.x >= GRID_WIDTH:
		return # Ignore this input, it's hitting a wall
	
	# 3. Floor/Lock Check
	# If we are moving DOWN and hit the floor
	if dir == Vector2.DOWN and target_pos.y >= FLOOR_Y:
		lock_piece()
		return
		
	# 4. Commit the Move
	piece.position = target_pos

func lock_piece() -> void:
	print("Locked at: ", piece.position)
	timer.stop()
	
	# Loop for MVP
	btn.text = "RESTART"
	btn.show()
