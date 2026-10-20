class_name Palette
extends RefCounted
## The shared storybook palette. Every world mesh uses one of these few
## materials, which keeps the look cohesive and draw-call friendly (materials
## are created once and shared).

const COLORS := {
	"grass": Color("8fb867"),
	"grass_dark": Color("6f9a52"),
	"path": Color("d9c49a"),
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
	"cloth_blue": Color("6d8fc0"),
	"cloth_red": Color("c96f5a"),
	"cloth_green": Color("7aa36a"),
	"cloth_cream": Color("efe3c6"),
	"cloth_gold": Color("d9a944"),
	"cloth_purple": Color("8c6fa8"),
	"skin_1": Color("f1c8a5"),
	"skin_2": Color("c99a72"),
	"skin_3": Color("8d5f42"),
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

static var _materials := {}


static func color(name: String) -> Color:
	return COLORS.get(name, Color.MAGENTA)


static func mat(name: String) -> StandardMaterial3D:
	if _materials.has(name):
		return _materials[name]
	var m := StandardMaterial3D.new()
	m.albedo_color = color(name)
	m.roughness = 0.9
	match name:
		"water":
			m.roughness = 0.2
			m.metallic_specular = 0.6
		"glass":
			m.emission_enabled = true
			m.emission = color(name)
			m.emission_energy_multiplier = 0.35
		"marker":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		"distant", "distant_dark":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_materials[name] = m
	return m
