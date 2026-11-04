extends SceneTree
## Cuts a sheet from pixelize.gd into one image per frame, trimmed to the art.
##
## Usage:
##   godot --headless --path <project> --script tools/split_row.gd -- \
##     --in assets/items/row.png --frame-w 30 --out-dir assets/items --names radish,carrot,pumpkin
##   An empty name skips that frame.


func _init() -> void:
	var args := _parse_args(OS.get_cmdline_user_args())
	var sheet := Image.load_from_file(ProjectSettings.globalize_path("res://" + args["in"]))
	sheet.convert(Image.FORMAT_RGBA8)
	var frame_w := int(args["frame-w"])
	var names: PackedStringArray = args["names"].split(",")
	for i in names.size():
		if names[i].is_empty():
			continue
		var frame := sheet.get_region(Rect2i(i * frame_w, 0, frame_w, sheet.get_height()))
		var trimmed := frame.get_region(frame.get_used_rect())
		var out: String = "%s/%s.png" % [args["out-dir"], names[i]]
		trimmed.save_png(ProjectSettings.globalize_path("res://" + out))
		print("saved ", out, " ", trimmed.get_size())
	quit()


func _parse_args(raw: PackedStringArray) -> Dictionary:
	var out := {}
	for i in range(0, raw.size() - 1, 2):
		out[raw[i].substr(2)] = raw[i + 1]
	return out
