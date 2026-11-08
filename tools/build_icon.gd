extends SceneTree
## Makes the game icon from its 64x64 pixel art: assets/icon/icon.png at 1024x1024, enlarged
## with hard edges so every pixel stays crisp on a phone's home screen. Rerun after changing
## assets/icon/icon_64.png (made from art_source/icon/icon-master.png with tools/pixelize.gd).

const SOURCE := "res://assets/icon/icon_64.png"
const OUT := "res://assets/icon/icon.png"
const SIZE := 1024


func _init() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	image.convert(Image.FORMAT_RGBA8)
	image.resize(SIZE, SIZE, Image.INTERPOLATE_NEAREST)
	image.save_png(ProjectSettings.globalize_path(OUT))
	print("saved %s (%dx%d)" % [OUT, SIZE, SIZE])
	quit()
