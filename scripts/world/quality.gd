class_name Quality
extends RefCounted
## Scenery quality tiers, so the world runs smoothly on modest tablets.
## "auto" picks Balanced on phones, tablets and the web, and High elsewhere.
## Each tier trims what costs most on a tablet GPU: dense meadow instances and
## how far they draw, forest density, the shadow map and which props cast
## shadows, how far faces keep their eyes and mouths, MSAA, and the 3D
## resolution (the UI always stays sharp).

const TIERS := {
	"high": {
		"cover_density": 1.0, "cover_range": 34.0, "forest_density": 1.0,
		"shadow_distance": 40.0, "shadow_size": 4096, "msaa": Viewport.MSAA_2X,
		"render_scale": 1.0, "mist": 1.0, "face_range": 22.0, "small_shadows": true, "lod_threshold": 1.0,
	},
	"medium": {
		"cover_density": 0.6, "cover_range": 26.0, "forest_density": 0.75,
		"shadow_distance": 28.0, "shadow_size": 2048, "msaa": Viewport.MSAA_2X,
		"render_scale": 0.85, "mist": 0.6, "face_range": 15.0, "small_shadows": false, "lod_threshold": 2.5,
	},
	"low": {
		"cover_density": 0.3, "cover_range": 20.0, "forest_density": 0.5,
		"shadow_distance": 18.0, "shadow_size": 1024, "msaa": Viewport.MSAA_DISABLED,
		"render_scale": 0.7, "mist": 0.3, "face_range": 11.0, "small_shadows": false, "lod_threshold": 5.0,
	},
}


## The tier in effect: the setting, or the device's default for "auto".
static func tier() -> String:
	var chosen := str(Settings.get_value("scenery_quality"))
	if TIERS.has(chosen):
		return chosen
	return "medium" if OS.has_feature("mobile") or OS.has_feature("web") else "high"


static func value(key: String) -> Variant:
	return TIERS[tier()][key]


## Applies the tier's screen-wide costs (MSAA, 3D resolution, shadow map).
## Scenery density takes effect the next time the world is built.
static func apply_viewport(viewport: Viewport) -> void:
	viewport.msaa_3d = value("msaa")
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	viewport.scaling_3d_scale = value("render_scale")
	viewport.mesh_lod_threshold = value("lod_threshold")
	RenderingServer.directional_shadow_atlas_set_size(int(value("shadow_size")), true)
