class_name Palette
extends RefCounted
## The shared storybook palette. Every procedural mesh uses one of these few
## materials (created once and shared), drawn with the storybook shader so it
## matches imported art.

const COLORS := {
	"grass": Color("8fb867"),
	"grass_dark": Color("6f9a52"),
	"path": Color("c9a97c"),
	"cobble": Color("c2b8a6"),
	"soil": Color("7a5236"),
	"soil_dark": Color("5c3d28"),
	"wood": Color("a8774f"),
	"wood_dark": Color("7b5338"),
	"wood_light": Color("d1a878"),
	"plaster": Color("f2e6cf"),
	"plaster_warm": Color("f0d9b5"),
	"stone": Color("b7aea0"),
	"stone_dark": Color("8d857a"),
	"roof_red": Color("b8584a"),
	"roof_blue": Color("5f7da0"),
	"roof_thatch": Color("c9a25a"),
	"roof_slate": Color("6c6a7a"),
	"leaf": Color("5e9a4e"),
	"leaf_light": Color("86b85a"),
	"leaf_autumn": Color("c9a24a"),
	"pine": Color("3f7a52"),
	"trunk": Color("7a5a3e"),
	"water": Color("6fa8c7"),
	"glass": Color("f7e7a8"),
	"glass_blue": Color("8fb2e8"),
	"glass_red": Color("e89a8f"),
	"glass_gold": Color("f2cf6e"),
	"smoke": Color("eef0f2"),
	"awning_red": Color("c8483c"),
	"awning_blue": Color("3f6fb0"),
	"awning_green": Color("4f8f4a"),
	"lantern": Color("ffd88a"),
	"cloth_blue": Color("6d8fc0"),
	"cloth_red": Color("c96f5a"),
	"cloth_green": Color("7aa36a"),
	"cloth_cream": Color("efe3c6"),
	"cloth_gold": Color("d9a944"),
	"cloth_purple": Color("8c6fa8"),
	"skin_1": Color("e3b08a"),
	"skin_2": Color("c99a72"),
	"skin_3": Color("8d5f42"),
	"skin_4": Color("d9a07a"),
	"cheek": Color("f0a79a"),
	"lips": Color("b8574f"),
	"eye_white": Color("fbf8f2"),
	"iris_brown": Color("5a3a22"),
	"iris_blue": Color("4b78b4"),
	"iris_green": Color("4f8a4a"),
	"hair_red": Color("b5582e"),
	"hair_black": Color("2a201c"),
	"monk_brown": Color("6e4b33"),
	"shoe": Color("4a3326"),
	"cloth_brown": Color("8a6244"),
	"cloth_tan": Color("c9a77c"),
	"bread": Color("c98a3e"),
	"dough": Color("f1e2c4"),
	"flour": Color("f7f2e8"),
	"leather": Color("6b4730"),
	"hair_brown": Color("6b4430"),
	"hair_dark": Color("3a2a22"),
	"hair_grey": Color("c9c3bb"),
	"hair_blond": Color("d9b56a"),
	"white": Color("f5f2ea"),
	"dark": Color("3b3430"),
	"gold": Color("e0b64c"),
	"flower_pink": Color("e88fa6"),
	"flower_yellow": Color("f1cf55"),
	"flower_white": Color("f6f1e4"),
	"flower_blue": Color("8fa8e0"),
	"sprout": Color("8ccf5a"),
	"bean_flower": Color("f4f0f8"),
	"felt_blue": Color("41577f"),
	"distant": Color("a9b6c8"),
	"distant_dark": Color("8e9bb0"),
	"marker": Color("ffd76a"),
}

## Painted surface pattern per palette colour (see shaders/patterns.gdshaderinc).
const PATTERNS := {
	"wood": 1, "wood_dark": 1, "wood_light": 1, "trunk": 1,
	"stone": 2, "stone_dark": 2,
	"roof_red": 3, "roof_blue": 3, "roof_slate": 3,
	"roof_thatch": 4,
	"plaster": 5, "plaster_warm": 5,
	"path": 6,
	"cobble": 9,
	"awning_red": 10, "awning_blue": 10, "awning_green": 10,
	"soil": 7, "soil_dark": 7,
	"cloth_brown": 8, "cloth_tan": 8,
	"cloth_cream": 8, "cloth_blue": 8, "cloth_red": 8, "cloth_green": 8, "cloth_gold": 8, "cloth_purple": 8, "felt_blue": 8,
}

static var _materials := {}


static func color(name: String) -> Color:
	return COLORS.get(name, Color.MAGENTA)


## Shared material for a palette colour. Most use the storybook shader; a few
## need special handling (glowing windows, the unlit marker, distant haze).
static func mat(name: String) -> Material:
	if _materials.has(name):
		return _materials[name]
	var m: Material
	match name:
		"water":
			m = Style.material("water")
		"glass", "glass_blue", "glass_red", "glass_gold", "lantern":
			m = Style.flat(color(name), {"emission_color": color(name) * 0.45})
		"marker":
			var s := StandardMaterial3D.new()
			s.albedo_color = color(name)
			s.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m = s
		"distant", "distant_dark":
			var d := StandardMaterial3D.new()
			d.albedo_color = color(name)
			d.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m = d
		"skin_1", "skin_2", "skin_3", "skin_4":
			# Skin: light wraps softly around the form, like a painted face.
			m = Style.flat(color(name), {"wrap": 0.4, "rim_strength": 0.08})
		"eye_white", "lips", "cheek":
			m = Style.flat(color(name), {"wrap": 0.8})
		"leaf", "leaf_light", "leaf_autumn", "pine", "sprout", "grass_dark":
			# Soft materials let light wrap around, like foliage.
			m = Style.flat(color(name), {"wrap": 0.5})
		_:
			var params := {}
			if PATTERNS.has(name):
				params["pattern"] = PATTERNS[name]
				if PATTERNS[name] == 8:
					params["pattern_strength"] = 0.35 # cloth: a hint of weave, not gingham
			if name.begins_with("cloth") or name == "white":
				params["wrap"] = 0.5
			m = Style.flat(color(name), params)
	_materials[name] = m
	return m
