class_name RoomRegion
extends FarRegion
## A room indoors (the Bellhaven library, the monastery scriptorium, Captain
## Mara's cabin), reached through a door in its place outside. It stands far
## off the map on its own floor, open at the front like a dollhouse so the
## camera looks in from above, with warm indoor light. No grass grows and no
## snow lies in it. A door inside takes the child back out to `exit_anchor`.

## The floor, wall and trim colours (Palette names).
var floor_color := "wood_light"
var wall_color := "plaster"
var trim_color := "wood_dark"


## Builds the room `size` (x by z) round the origin, arrival just inside the
## open front, and the way back out.
func room(size: Vector2, exit_anchor: String, exit_prompt: String) -> void:
	var half := size / 2.0
	area = Rect2(-half.x + 0.4, -half.y + 0.4, size.x - 0.8, size.y - 0.8)
	lay_ground(Vector3(0, 0, half.y - 1.2), 0.0)
	# Floor, and dark ground all round so the room never floats in the sky.
	MeshKit.box(self, Vector3(size.x, 0.2, size.y), Vector3(0, -0.1, 0), floor_color)
	MeshKit.box(self, Vector3(size.x + 60.0, 0.1, size.y + 60.0), Vector3(0, -0.3, 0), "dark")
	# Back and side walls full height; a low front wall either side of the door.
	MeshKit.box(self, Vector3(size.x + 0.4, 3.4, 0.3), Vector3(0, 1.7, -half.y - 0.15), wall_color, true)
	for side: float in [-1.0, 1.0]:
		MeshKit.box(self, Vector3(0.3, 3.4, size.y), Vector3(side * (half.x + 0.15), 1.7, 0), wall_color, true)
		MeshKit.box(self, Vector3(half.x - 1.0, 0.6, 0.3), Vector3(side * (half.x + 1.0) / 2.0, 0.3, half.y + 0.15), wall_color, true)
		# Timber posts at the corners and along the top of the walls.
		MeshKit.box(self, Vector3(0.36, 3.5, 0.36), Vector3(side * (half.x + 0.15), 1.75, -half.y - 0.15), trim_color)
	MeshKit.box(self, Vector3(size.x + 0.6, 0.2, 0.4), Vector3(0, 3.45, -half.y - 0.15), trim_color)
	add_interior("home", Vector3(0, 1.5, 0), Vector3(size.x, 3.0, size.y), [])
	add_camera_zone(Vector3(0, 1.5, 0), Vector3(size.x, 3.0, size.y), {"pitch": 52.0, "distance": 11.5, "height": 0.8, "fov": 42.0})
	# The way back out, by the door.
	var out := Interactable.create(self, Vector3(0, 0, half.y - 0.3), exit_prompt, func() -> void:
		(get_parent() as World).move_player_to_anchor(exit_anchor), 0.7, 1.6)
	out.reach = 1.8


## A door into a room from outside: the child steps through to the room's
## arrival spot. Used by the places outside.
static func door(region: Region, at: Vector3, prompt: String, room_id: String) -> Interactable:
	var d := Interactable.create(region, at, prompt, func() -> void:
		(region.get_parent() as World).travel_to(room_id), 0.7, 1.8)
	d.reach = 2.0
	return d


## A window on the back wall, letting in the daylight.
func window(at: Vector3, size := Vector2(1.2, 1.0)) -> void:
	MeshKit.box(self, Vector3(size.x + 0.2, size.y + 0.2, 0.08), at, trim_color)
	MeshKit.box(self, Vector3(size.x, size.y, 0.09), at + Vector3(0, 0, 0.01), "glass")
	MeshKit.box(self, Vector3(0.06, size.y, 0.1), at + Vector3(0, 0, 0.02), trim_color)
