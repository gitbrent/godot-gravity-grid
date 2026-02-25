@tool
extends EditorScript

func _run() -> void:
	generate_standard_block()
	generate_ghost_block()

func generate_standard_block() -> void:
	# (This recreates your existing solid block to be safe)
	var size = 32
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var dark = Color(0.4, 0.4, 0.4, 1.0)
	var light = Color(1.0, 1.0, 1.0, 1.0)
	var face = Color(0.9, 0.9, 0.9, 1.0)
	var border_width = 4
	
	for y in range(size):
		for x in range(size):
			img.set_pixel(x, y, face)
			if x < border_width or y < border_width: img.set_pixel(x, y, light)
			elif x >= size - border_width or y >= size - border_width: img.set_pixel(x, y, dark)
			if x < border_width and y >= x and y < size - x: img.set_pixel(x, y, light)

	save_texture(img, "res://assets/block_bevel.tres")

func generate_ghost_block() -> void:
	# --- NEW GHOST LOGIC ---
	var size = 32
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Transparent background
	img.fill(Color(0, 0, 0, 0)) 
	
	var border_color = Color(1.0, 1.0, 1.0, 0.6) # Bright, semi-transparent white
	var border_width = 2 # Thinner outline for ghost
	
	for y in range(size):
		for x in range(size):
			# Only draw pixels if they are on the edge
			if x < border_width or y < border_width or x >= size - border_width or y >= size - border_width:
				img.set_pixel(x, y, border_color)

	save_texture(img, "res://assets/ghost_bevel.tres")

func save_texture(img: Image, path: String) -> void:
	var texture = PortableCompressedTexture2D.new()
	texture.create_from_image(img, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
	ResourceSaver.save(texture, path)
	print("Saved: " + path)
