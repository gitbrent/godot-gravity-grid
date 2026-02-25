extends Node

@onready var sfx_move: AudioStreamPlayer = $SfxMove
@onready var sfx_rotate: AudioStreamPlayer = $SfxRotate
@onready var sfx_lock: AudioStreamPlayer = $SfxLock
@onready var sfx_clear: AudioStreamPlayer = $SfxClear
@onready var sfx_game_start: AudioStreamPlayer = $SfxGameStart
@onready var sfx_game_over: AudioStreamPlayer = $SfxGameOver

func play_move() -> void:
	if not sfx_move.playing: # Prevent overlapping spam
		sfx_move.play()

func play_rotate() -> void:
	sfx_rotate.play()

func play_lock() -> void:
	sfx_lock.play()

func play_clear() -> void:
	sfx_clear.play()

func play_game_start() -> void:
	sfx_game_start.play()

func play_game_over() -> void:
	sfx_game_over.play()
