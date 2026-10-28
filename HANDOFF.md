# Handoff

Notes for the next agent (or the next session of this one) picking up The
Good Garden. Read this first, then `docs/ROADMAP.md` (what is built and what
comes next) and `docs/ARCHITECTURE.md` (how it fits together). The design
intent lives in `docs/design/`, starting with `AGENT_START_HERE.md`.

Last updated: 2026-10-28.

## Where things stand

- **The full 12-week season is built**: 85 days in `content/days/`, from the
  first letter to the Harvest Supper. 87 activities in `content/activities/`
  use about 20 reusable activity types.
- **The valley** is the home world: home, Miss Miriam's garden, the
  village, the chapel and Atrium, the mill, the oven, the orchard, the
  pond, the sheepfold and the Grove.
- **Seven places in the wider world** open one by one, from day 22 to
  day 71: the Wilderness, the Farmlands, the Lake, Bellhaven, the
  Monastery, the Coast and the Mountains. Each has someone to meet and two
  jobs. `docs/ROADMAP.md` has the table of who is where and when each
  opens.
- **The wider-world map** is laid out after the owner's concept image,
  `docs/design/reference/concept_map.png`. Use that image as the visual
  guide for the world, the map and the places. Its bottom row shows
  in-game mockups of the village, the city, the harbour, the monastery,
  the wilderness and the map.
- **Tests:** 928 checks, all passing, as of the last commit.

## How to work here

**Engine.** Godot 4.3, GDScript. In the cloud container it lives at
`/opt/godot/Godot_v4.3-stable_linux.x86_64`.

**Before the first run on a fresh clone**, build the class cache. Do this
again whenever you add assets or a new `class_name`:

    godot --headless --path . --editor --quit

**Tests.** They take about 15–20 minutes, so run them in the background.
Expect one `SaveService: save is from a newer version (99)` error line: it
comes from a test that checks future saves are refused.

    godot --headless --path . res://tests/test_runner.tscn

**Content validator:**

    godot --headless --path . res://tools/validate_content.tscn

**Looking at the game.** Render screenshots under a virtual display:

    xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
      --rendering-driver opengl3 --resolution 1280x720 res://tools/<tool>.tscn -- --out=<dir>

- `tools/screenshot_tour.gd` is a base class for render tools: it provides
  `_settle`, `shot` and `_close_modals`.
- For a one-off view, write a throwaway `tools/_something.gd` and `.tscn`
  that extend it. Delete them before committing.
- `tools/board_gallery.tscn` renders the activity boards (`--only=ids`).
- Each render takes several minutes on the CPU renderer.
- Look at every render before you call a visual change done.

**Committing.**
- Work on the branch you were given. This project's habit is to push the
  branch and then `main`:
  `git push -u origin <branch>` then `git push origin HEAD:main`.
- No pull requests unless the owner asks for one.
- Keep the tree clean at the end of a turn. Never commit temporary
  `tools/_*` files.

## The owner's standing decisions

- **Ages 5–10.** Plain, warm wording.
- **"We don't stroke pets, we pet them."**
- **Free CC0 assets only.** Record every third-party asset in
  `assets/third_party/manifest.json` and `docs/design/THIRD_PARTY_ASSETS.md`.
- **Artlist AI generation** is shared across four games. Get the exact
  price and the owner's go-ahead before every generation, and log it in
  `docs/ARTLIST_SPENDING.md`.
- **Paused:** new Scripture presentations (parables) and narration
  recordings. Don't resume them unless the owner asks.
- **Builds:** no Mac zip or other build unless asked.
- **Questions:** only bother the owner for major next steps. Otherwise use
  judgement, finish the work and report.

## Where the wider world lives in the code

- **`scripts/world/terrain.gd`** is the one source of truth for the
  landscape:
  - `SITES`: each place's centre and radius of level ground. The radius
    must cover the place's whole walkable area. An entry can also set its
    own level, and a waterside flag so the site never fills the water.
  - `SITE_SLOPE`: how far each site slopes back into the hills.
  - `ROADS`: the dirt roads, painted by `shaders/ground.gdshader`.
  - `WAYSIDES`: the scenery along the roads.
  - `PEAKS`: the snowy range behind the mountain meadow.
  - The sea (`SEA_X`), the lake (`LAKE`) and the river's course
    (`RIVER_KNOTS`).
- **`scripts/world/far_region.gd`** and **`scripts/world/regions/*_region.gd`**
  hold each place's layout, in local coordinates centred on its site.
  `area` is the walkable rectangle. The coast and the lake find their
  shoreline from `Terrain.height`.
- **`scripts/world/waysides.gd`** builds the roadside scenery. It also
  builds the map-only painted landmarks: they sit on `Waysides.MAP_LAYER`,
  which only the map camera draws.
- **`scripts/ui/map_panel.gd`** has the valley map and the wide view of
  the wider world (`show_wide`).
- **`content/world/regions.json`** says when each place opens.
  **`content/world/job_spots.json`** holds each place's job spots, in local
  coordinates.
- **Moving a place** means moving its site centre. Then:
  - update its road's last points and any landmarks or waysides near it;
  - check the test "…'s ground lies level under its walkable area";
  - make sure sites stay apart: their flat ground plus about 20 m of slope
    shouldn't overlap a neighbour's, especially when their levels differ.

## Lessons learned the hard way

- **Probe heights before rendering.** For any terrain change, sample
  `Terrain.height` in a throwaway headless script (`extends SceneTree`)
  before rendering. Check every site's level and the valley edge.
- **Check the whole world after a "local" terrain fix.** A river-bank fix
  once grew with the height of the land and flattened ground hundreds of
  metres away.
- **Never use `pkill -f <name>` in the same shell command as a new run.**
  It matches its own command line and kills that command.
- **Read every script you rewrite to the end.** Text-replacing "from here
  to the end of the file" once deleted the coast's lighthouse function.

## What to do next

These are the open threads, roughly in the order the owner would likely
want them. Confirm with the owner before starting anything large.

1. **Map polish.** A pale rocky hill sits in the bottom-right corner of the
   wider-world map, south of the coast. Soften it, for example by lowering
   or greening the southern hills near the sea.
2. **Second season.** Write story days that visit the wider-world places,
   rather than only free jobs there (`docs/ROADMAP.md`, "The wider world").
3. **Interiors.** The Bellhaven library, the monastery scriptorium and
   Captain Mara's ship.
4. **Walking between places.** Travel is by the map today. The painted
   roads could become walkable.
5. **Alongside work**, listed in `docs/ROADMAP.md` under "Alongside, when
   it fits": identity art, tablet performance, translation, and the
   theological, educational and child-privacy reviews before release.

Keep this file current. Update it when a thread finishes or a new decision
is made.
