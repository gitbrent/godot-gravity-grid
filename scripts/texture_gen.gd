@tool
extends EditorScript

### One-Off script to execute once in the code IDE

func _run() -> void:
	generate_bevel_texture()

func generate_bevel_texture() -> void:
	# 1. Setup - 32x32 is standard for Tetris
	var size = 32 
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# 2. Colors
	var dark = Color(0.4, 0.4, 0.4, 1.0)  # Shadow (Bottom/Right)
	var light = Color(1.0, 1.0, 1.0, 1.0) # Highlight (Top/Left)
	var face = Color(0.9, 0.9, 0.9, 1.0)  # Main Face
	var border_width = 4
	
	# 3. Draw Pixels
	for y in range(size):
		for x in range(size):
			# Default to Face color
			img.set_pixel(x, y, face)
			
			# Bevel Logic (Top-Left Light, Bottom-Right Dark)
			if x < border_width or y < border_width:
				img.set_pixel(x, y, light)
			elif x >= size - border_width or y >= size - border_width:
				img.set_pixel(x, y, dark)
			
			# Clean up corners (Optional crisp diagonal)
			if x < border_width and y >= x and y < size - x:
				img.set_pixel(x, y, light)

	# 4. Save
	var texture = PortableCompressedTexture2D.new()
	texture.create_from_image(img, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
	ResourceSaver.save(texture, "res://assets/block_bevel.tres")
	print("Success! Texture saved to res://assets/block_bevel.tres")
