# Godot Gravity Grid

A classic falling block puzzle game built with Godot 4, featuring smooth controls, progressive difficulty, and polished visual effects.

![game-screenshot](https://github.com/user-attachments/assets/a78b49aa-c140-4c73-9286-5e1d926292e4)

## Features

- **Classic Tetromino Gameplay**: All 7 standard pieces (I, O, T, S, Z, J, L)
- **Hold Piece System**: Store one piece for later use
- **Ghost Piece**: See where your piece will land
- **Progressive Difficulty**: Speed increases every 10 lines cleared
- **Scoring System**:
  - Soft drop: 1 point per cell
  - Hard drop: 2 points per cell
  - Line clears: 100-800 points (multiplied by current level)
- **Smooth Controls**:
  - DAS (Delayed Auto Shift) for responsive movement
  - Wall kicks for flexible rotation
  - Hard drop for instant placement
- **Visual Polish**:
  - Beveled block textures
  - Semi-transparent ghost pieces
  - Particle effects on line clears
  - Progress ring showing level advancement

## Controls

|Action|Key|
|--------|-----|
|Move Left|← Left Arrow|
|Move Right|→ Right Arrow|
|Soft Drop|↓ Down Arrow|
|Hard Drop|Space|
|Rotate|↑ Up Arrow|
|Hold Piece|Shift|

## Gameplay

1. Guide falling tetrominoes to create complete horizontal lines
2. Complete lines are cleared and award points
3. The game speeds up every 10 lines cleared
4. Use the hold feature strategically to save pieces for later
5. The ghost piece shows where your piece will land
6. Game ends when a new piece can't be placed at the top

## Technical Details

- **Engine**: Godot 4.x
- **Language**: GDScript
- **Core Systems**:
  - [`scenes/game.gd`](scenes/game.gd): Main game logic, piece movement, collision detection
  - [`scenes/sound_manager.gd`](scenes/sound_manager.gd): Audio management
  - [`scripts/progress_ring.gd`](scripts/progress_ring.gd): Custom UI element for level progression
  - [`scripts/texture_gen.gd`](scripts/texture_gen.gd): Tool script for generating block textures

## Building from Source

1. Clone the repository

```bash
git clone https://github.com/brentely/godot-gravity-grid.git
cd godot-gravity-grid
```

1. Open the project in Godot 4.x
2. Run the project (F5)

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Credits

Created with Godot Engine
