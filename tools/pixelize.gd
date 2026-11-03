extends SceneTree
## Shrinks AI-generated "pixel art" to its real pixel size.
##
## Finds each sprite in a horizontal strip (separated by transparent columns),
## samples the center of every art pixel, and packs the sprites into a sheet of
## equal frames, bottom-aligned and centered.
##
## Usage:
##   godot --headless --path <project> --script tools/pixelize.gd -- \
##     --in art_source/player/player_directions.png \
##     --out assets/player/player_idle.png \
##     --height 64 --frame-w 48 --frame-h 64

func _init() -> void:
	var args := _parse_args(OS.get_cmdline_user_args())
	var in_path: String = args.get("in", "")
	var out_path: String = args.get("out", "")
	if in_path.is_empty() or out_path.is_empty():
		push_error("Need --in and --out")
		quit(1)
		return
	var target_h := int(args.get("height", "64"))
	var frame_w := int(args.get("frame-w", "48"))
	var frame_h := int(args.get("frame-h", str(target_h)))

	var src := Image.load_from_file(ProjectSettings.globalize_path("res://" + in_path))
	src.convert(Image.FORMAT_RGBA8)

	var boxes := _find_sprites(src)
	if boxes.is_empty():
		push_error("No sprites found")
		quit(1)
		return

	# One scale for all sprites, so they keep the same pixel size.
	var tallest := 0
	for box: Rect2i in boxes:
		tallest = max(tallest, box.size.y)
	var scale := float(tallest) / target_h
	print("sprites: %d, art pixel size: %.2f source px" % [boxes.size(), scale])

	var sheet := Image.create(frame_w * boxes.size(), frame_h, false, Image.FORMAT_RGBA8)
	for i in boxes.size():
		var box: Rect2i = boxes[i]
		var w := int(round(box.size.x / scale))
		var h := int(round(box.size.y / scale))
		var ox := i * frame_w + (frame_w - w) / 2
		var oy := frame_h - h
		if w > frame_w or h > frame_h:
			push_warning("Sprite %d is %dx%d, larger than the frame" % [i, w, h])
		for y in h:
			for x in w:
				var sx := box.position.x + int((x + 0.5) * scale)
				var sy := box.position.y + int((y + 0.5) * scale)
				var c := src.get_pixel(min(sx, src.get_width() - 1), min(sy, src.get_height() - 1))
				c.a = 1.0 if c.a > 0.5 else 0.0
				var px := ox + x
				var py := oy + y
				if px >= i * frame_w and px < (i + 1) * frame_w and py >= 0:
					sheet.set_pixel(px, py, c)
		print("sprite %d: %dx%d" % [i, w, h])

	sheet.save_png(ProjectSettings.globalize_path("res://" + out_path))
	print("saved ", out_path, " (", sheet.get_width(), "x", sheet.get_height(), ")")
	quit()


func _parse_args(raw: PackedStringArray) -> Dictionary:
	var out := {}
	var i := 0
	while i < raw.size():
		if raw[i].begins_with("--") and i + 1 < raw.size():
			out[raw[i].substr(2)] = raw[i + 1]
			i += 2
		else:
			i += 1
	return out


## Bounding boxes of sprites separated by fully transparent columns.
func _find_sprites(img: Image) -> Array[Rect2i]:
	var boxes: Array[Rect2i] = []
	var w := img.get_width()
	var h := img.get_height()
	var start := -1
	for x in w + 1:
		var has := false
		if x < w:
			for y in h:
				if img.get_pixel(x, y).a > 0.5:
					has = true
					break
		if has and start == -1:
			start = x
		elif not has and start != -1:
			var top := h
			var bottom := 0
			for cx in range(start, x):
				for y in h:
					if img.get_pixel(cx, y).a > 0.5:
						top = min(top, y)
						bottom = max(bottom, y)
			boxes.append(Rect2i(start, top, x - start, bottom - top + 1))
			start = -1
	return boxes
