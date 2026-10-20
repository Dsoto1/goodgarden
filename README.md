# The Good Garden — Vertical Slice

A calm, Christian, Montessori-inspired learning adventure for ages 6–10, built in **Godot 4.3** with GDScript. This repository holds the **vertical slice** described in [`docs/design/VERTICAL_SLICE.md`](docs/design/VERTICAL_SLICE.md). It proves the core loop: explore → notice a need → do a hands-on activity → see the world change → keep exploring.

Design direction lives in [`docs/design/`](docs/design) (start with `AGENT_START_HERE.md`). How the code is organised is in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), and how to write new days, activities and dialogue is in [`docs/CONTENT_GUIDE.md`](docs/CONTENT_GUIDE.md).

## Running it

1. Install [Godot 4.3](https://godotengine.org/download/archive/4.3-stable/) (the standard build, not .NET).
2. Open `project.godot` in the editor and press **Play**, or run `godot --path .` from this folder.

The project uses the **GL Compatibility** renderer so it runs on modest tablets, older laptops and (later) the web.

### Controls

| | Mouse / touch | Keyboard | Gamepad |
|---|---|---|---|
| Walk | Tap or hold on the ground | WASD / arrows | Left stick / D-pad |
| Use / talk | Tap the thing (the child walks over), or tap the green prompt | E / Space / Enter | A |
| Move pieces in an activity | Drag | Mouse | Left stick moves a hand cursor, **X** grabs/drops (keyboard: arrows + **G**) |
| Journal / Map / Pause | Buttons, top right | J / M / Esc | Y / Back / Start |

The camera follows on its own; the child never has to steer it.

## What's in the slice

| Required (VERTICAL_SLICE.md) | Where |
|---|---|
| Begin at Home, receive Miriam's Invitation | Letter on the stand by the cottage door (`home_region.gd`, `content/invitations/`) |
| Walk to the Garden, talk with Miriam | `garden_region.gd`, `content/dialogue/miriam.json` |
| Gardening activity: seed spacing + counting with self-correction | `content/activities/garden_bean_row.json` (spacing stick → three seeds per hole) |
| Planted bed persists and grows | `garden.bed_1` world fact; sprouts on day 2, seedlings on day 3, climbing plants after |
| Practical-life activity reusing the framework | `content/activities/home_set_table.json` (placemat outlines) |
| Chapel/Atrium with a Scripture material | `chapel_region.gd`, `content/activities/good_samaritan.json` (listen, wonder, retell, put away; never scored) |
| Chapel feels different | World "chapel" mood: dimmer warm light, a separate synthesized soundscape, quieter HUD, tabletop framing |
| Journal / Invitation flow | Journal records letters, the child's work, and optional real-world invitations |
| Save, quit, reload | Versioned save (`SaveService`), restored world facts, journal, discoveries and position |
| Village path, ambient villagers and animals, Bellhaven in the distance | `village_region.gd`, `valley_region.gd`, `bellhaven_vista.gd` (see it from the overlook north of the village) |

Also included: rest-until-morning day advance, an illustrated map that offers travel only to discovered places, settings (text size, read-aloud, less motion, easier dragging, volumes), and a gated grown-ups page with plain-language observations (never grades, never inferences about faith).

## Tests and checks

```sh
# Unit tests plus an end-to-end playthrough of the required flow
godot --headless --path . res://tests/test_runner.tscn

# Content validation only (ids, references, effect tokens, speakers, asset manifest)
godot --headless --path . res://tools/validate_content.tscn
```

Run `godot --headless --path . --editor --quit` once first on a fresh clone so Godot builds its class cache. Both commands exit non-zero on failure. Expect one `ERROR: SaveService: save is from a newer version (99)` line in the test output: that test checks that future saves are refused.

To render review screenshots (needs a display or Xvfb):

```sh
xvfb-run godot --path . --rendering-driver opengl3 --resolution 1280x720 \
  res://tools/screenshot_tour.tscn -- --out=/absolute/output/dir
```

## Assets

The slice ships **no third-party assets**. All geometry is assembled from primitive meshes (`scripts/world/mesh_kit.gd`), all UI art is drawn in code, and all sound is synthesized at runtime. The machine-readable manifest at `assets/third_party/manifest.json` is checked by the content validator: any file added under `assets/third_party/` without a complete entry fails validation. This follows the CC0-first policy in `docs/design/ASSET_STRATEGY.md`.

## Review status

The Good Samaritan retelling and wondering questions are an **original draft** written for this prototype (`review_status` in the JSON). Scripture wording, curriculum and child-safety choices need qualified theological, educational and privacy review before any release, as the design docs require.

## Screenshots

Rendered with the software renderer by `tools/screenshot_tour.tscn`; art is placeholder.

| Miriam's garden | Spacing the bean row | Bellhaven from the overlook |
|---|---|---|
| ![](docs/screenshots/04_garden_miriam.png) | ![](docs/screenshots/06_spacing_check.png) | ![](docs/screenshots/11_bellhaven_vista.png) |

| The Good Samaritan (Atrium) | Day 2: the beans have sprouted |
|---|---|
| ![](docs/screenshots/13_story.png) | ![](docs/screenshots/16_day2_sprouts.png) |
