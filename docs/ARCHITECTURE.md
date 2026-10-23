# Architecture

How the vertical slice maps onto `docs/design/TECH_SPEC.md`, and the decisions behind it.

## Layout

```
autoload/            Services (one small file each, registered in project.godot)
content/             Authored data: activities, days, dialogue, invitations, real_world, world
scenes/              Thin .tscn shells: main, activity workspace, one scene per world region
scripts/
  main.gd            Title → game flow, UI layers, requests from the world ("main" group)
  activity/          ActivityDefinition, workspace, drag pieces, slots, piece art, primitives/
  world/             World, regions/, player, camera, interactables, zones, NPCs, mesh kit
  ui/                HUD, dialogue box, letters, journal, map, menus, theme
tools/               Content validator, screenshot tour
tests/               Headless test runner (unit + end-to-end)
```

## Services (autoloads)

| TECH_SPEC system | Autoload | Notes |
|---|---|---|
| GameState | `GameState` | Mode stack (TITLE, EXPLORE, DIALOGUE, ACTIVITY, REFLECTION, MENU, TRANSITION) decides who owns input. |
| SaveService | `SaveService` | JSON in `user://saves/`, `schema_version` from day one, step-by-step migrations, refuses saves from newer versions. |
| WorldStateService | `WorldState` | Dotted-key facts plus a small condition language (`exists`, `equals`, `at_least`, `is_today`, `day`, `day_at_least`, `any`, `not`) and effects with `$token` substitution. |
| Day/SeasonService | `Days` | Current day and its definition; day 0 is the "free day" template for days past authored content. |
| InvitationService | `Invitations` | Today's unread letter; opening it journals it. |
| InteractionService | `Interaction` | Picks the nearest, most-faced interactable; mouse, touch, keyboard and gamepad all end in the same `interact()`. |
| DialogueService | `Dialogue` | Data-driven conversations; entry points guarded by conditions, so characters remember. Activities requested in dialogue start after it closes. |
| ActivityRunner | `ActivityRunner` | Owns the activity lifecycle: prerequisites, workspace, observations, world effects, journal, real-world invitation, autosave. |
| ActivityDefinition | `scripts/activity/activity_definition.gd` | Typed view over the JSON. |
| Manipulative components | `DragPiece`, `DropSlot`, `PieceArt`, `ActivityStep` | Shared by every primitive. |
| Asset normalization | `Props` + `assets/props.json` | Imported models placed by id with scale, pivot offset, collision and an optional palette `tint` from data. Changing an id's model (e.g. KayKit trees to Quaternius) is a data-only change. |
| LearningObservationService | `Observations` | Local log; `summarize()` gives plain sentences. Reflection activities only report that a material was chosen and time spent retelling. |
| JournalService | `Journal` | Letters, work, optional real-world invitations (a "We tried it" tick that costs nothing when left blank). |
| Map/DiscoveryService | `Discovery` | Places walked to; the map unlocks after three and offers travel only there. |
| AudioService | `AudioService` | Synthesized ambience and soft cues; read-aloud through the platform's text-to-speech when available, with captions always on screen. |
| AccessibilitySettings | `Settings` | Per-device JSON in `user://settings.json`, kept separate from the save. |
| — | `Content` | Loads every JSON under `content/` once at boot. |
| — | `InputSetup` | Input actions registered in code (keys, gamepad buttons and axes). |

## Activities: definition → primitive → world

An activity JSON lists **steps**. Each step names a **primitive**, a reusable manipulation registered in `PrimitiveRegistry`:

| Primitive | Montessori idea | Control of error | Used by |
|---|---|---|---|
| `space_along_line` | measure with a non-standard unit | a ghost stick in each gap shows overlap (too close) or bare ground (too far), hatched rather than coloured | bean row spacing |
| `count_into_slots` | one-to-one correspondence, equal groups | each hole shows N dimples; a seed dropped into a full hole rolls back | sowing seeds |
| `match_to_outline` | matching, sorting, care of materials | the wrong piece shakes and slides back from an outline it doesn't fit | table setting, putting Atrium figures away |
| `sequence_cards` | order, cause and effect, growth over time | when every place is filled, cards out of order slide back | how an apple tree grows |
| `story_figures` | story manipulation and retelling | none by design: no checks, timers or score | Good Samaritan |

Steps never write world state. They emit `completed(result)`, and the runner turns results into facts through the definition's `world_effects`, e.g. `"positions": "$space_holes.positions"`. Regions read facts back and rebuild themselves in `sync_with_world()`, which is how the planted row survives reloads and grows over days.

Every step runs on a 1000×560 design-unit board that the workspace scales to fit the screen, so primitives never deal with resolution. Snap tolerance comes from settings ("Easier dragging") in screen pixels and is converted to board units.

## World

- **The wider world:** `FarRegion` places (Bellhaven, the monastery, the coast, the lake, the farmlands, the wilderness, the mountains) each stand on a level site in `Terrain.SITES`, cut into the hills where the concept map puts them (`regions.json` `"site"`). Each brings its own ground collider, invisible edges, arrival anchor and a camera zone turned toward its view; `World` bakes a navigation mesh and grows grass for each. They open by day (`"open_when"`), and the map's "wider world" view travels there. `Terrain` also lowers the land into a sea east of `SEA_X` and a lake hollow at `LAKE`, which `World` covers with water. A site by the water (one given its own level) only cuts the hills down, so the shore stays natural; the coast and the lake find their shoreline from `Terrain.height` and lay the dock and jetty from it. A range of snowy peaks rises at `PEAKS`, behind the mountain meadow. `Terrain.ROADS` are dirt roads from the valley to each place, painted by the ground shader (with sandy shores by the sea and the lake); the forest keeps off them. `Waysides` builds the life along them from `Terrain.WAYSIDES`: farmsteads, windmills, a watermill, hamlets, a shepherd's hut and a stone bridge where the monastery road crosses the river. Out in the hills the camera rig keeps above the slope behind the child. The map's wider-world view looks at a slant from the south, like the concept's painted map, with small tags for the places.
- **Regions** (`scripts/world/regions/*.gd`) are independent scenes placed by `content/world/regions.json`. Each builds its geometry in local space, publishes **anchors** (spawn points, NPC spots), **discovery zones**, **interior zones** (which hide the roof and front wall and set the mood) and **camera zones** (e.g. the Bellhaven vista). Streaming regions by distance later only changes how `World` loads them.
- **Navigation:** `World` bakes a navigation mesh at runtime from the static colliders (about half a second), so tap-to-walk goes through doors and gates. Characters use their own physics layer and are left out of the bake.
- **Camera:** `CameraRig` follows at a fixed elevated three-quarter angle. Zones and focus requests reframe it (conversation, activity close-up, chapel, vista); with reduced motion it cuts instead of gliding.
- **Mood:** `World.set_mood()` tweens light and ambience between outdoor, home and chapel, and quiets the HUD in the chapel.

## Look: one style for every source

- **Shaders (`shaders/`):** all world surfaces use the storybook shaders. That covers procedural pieces, KayKit, Quaternius and the characters. `storybook_common.gdshaderinc` is the shared lighting: a soft two-tone terminator, cool-tinted shade and a faint rim light. Variants:
  - `storybook.gdshader`: solid surfaces.
  - `storybook_foliage.gdshader`: alpha-cut, two-sided, wind sway.
  - `ground.gdshader`: patchy meadow greens.
  - `water.gdshader`: drifting ripples.
- **Global uniforms (`project.godot` `[shader_globals]`):** `gg_wind` is set to 0 by "Less motion", `gg_shadow_tint` controls shade colour, and `gg_light_scale` is 1/π because Godot passes LIGHT_COLOR to custom light functions with π folded in.
- **Painted patterns (`patterns.gdshaderinc`):** world-space patterns give procedural pieces texture without photo textures: wood planks, stone blocks, shingles, thatch, plaster, earth paths, cobbles, soil and cloth. `Palette.PATTERNS` maps palette colours to patterns.
- **`Style`:** converts imported glTF materials to the storybook shaders once and caches them. `assets/props.json` `grades` pull each pack toward the shared palette (saturation, tint, light wrap). Quaternius vertex colours are shader masks, not colour, so that pack sets `ignore_vertex_color`. Grass sets `up_normals` and `root_shade` so it lights like the ground it grows from.
- **`GroundCover`:** grass, clover and wildflower meadows instanced with MultiMesh in 10 m chunks (drawn to 34 m, no shadows). It grows everywhere except each region's `clearings` (floors, paths, beds, plaza), clusters by noise, and fringes path edges with tufts and pebbles. "Less scenery detail" lowers density to 40%: about 1.7M → 0.67M triangles map-wide, of which only nearby chunks in view are drawn.

## Landscape and framing (toward the concept mockup)

- **`Terrain`:** one height function. The walkable valley floor (`Terrain.FLOOR`) stays level so play spaces, paths and interiors are predictable. Beyond it the land rolls into hills and, far off, ridged snow-capped mountains. There's a low corridor north so Bellhaven stays visible from the overlook, low ground where the river leaves the valley, and a plateau under the city. The landscape mesh, distant forests and Bellhaven's placement all use it; `ground.gdshader` colours it by height and slope (meadow, forest floor, rock, snow).
- **River, bridge and waterfall:** `Terrain` carves the river channel and raises a western plateau. The river drops off it in `Waterfall` (a streaming sheet using `falls.gdshader`, a foam pool, mist and rocks). `StoneBridge` is one masonry mesh: a cobbled hump deck with a sloped collider, written in both windings so the navmesh baker sees a walkable top, plus an arch, voussoir ring, parapets and pillars. A riverbank camera zone east of the bridge turns the view west so the arch and the falls share the frame.
- **`Forest`:** several thousand cheap low-poly trees on the hills, instanced per 40 m chunk with per-instance greens and no shadows. The detailed Quaternius trees stay near the play area.
- **Camera:** a low over-the-shoulder view (`CameraRig.DEFAULT_FRAMING`, 18° pitch) that shows the horizon, like the mockup's play screens. Interiors push a higher framing. A spring arm moves in when walls block the view, ignoring invisible blockers (`MeshKit.LAYER_INVISIBLE`: river banks, world edge).
- **Light:** golden-afternoon sun with longer shadows and blue aerial haze.
- **HUD:** the place name (from `Discovery.entered`), "Day N • Season" (`Days.season()`), a Today's Invitation card (each invitation's `summary`), and Journal / Map / Settings icon tiles (`scripts/ui/icon.gd`). The serif font is EB Garamond (OFL).

## Characters

`CharacterModel` builds storybook people with big friendly heads and clearly child-sized children.

- **The body is one smooth, skinned mesh** (`BodyMesh`): torso, legs, arms, hands and feet are lofted as continuous tubes with tapering profiles (thigh to knee to calf, shoulder to elbow to wrist) and bound to a 17-bone skeleton.
- **Joints blend:** near each hip, knee, shoulder and elbow, vertex weights cross-fade between the two bones, so limbs bend smoothly rather than hinging like separate parts.
- **Clothing is colour regions on that surface:** trousers, shirt, sleeves with cuffs, belt band, open vest, shoes. So there are no seams. Skirts, aprons, the backpack and the basket ride on bones as separate soft pieces.
- **Head:** eyes with irises and highlights, brows, nose, cheeks and a smile, plus hairstyles, beards, hats and scarves. It rides the head bone.
- **Animation is procedural and drives bone poses:** a walk with knee bend and arm swing, breathing, blinking, idle glances, a mouth that moves while talking, and gestures. NPCs and talking villagers turn toward the child.
- **Looks are data** in `content/world/characters.json` (named characters, the player, and ambient `villagers`); the validator checks every colour they name against the palette.
- **Review tool:** `tools/character_lineup.tscn` renders the cast front-on, close up and mid-stride.

I evaluated Quaternius's free Universal Base Characters (CC0) and didn't use them: they are realistic, muscular adult bodies in underwear, with no children, and would clash with the storybook style. The CC0 Universal Animation Library could drive a rigged custom character later.

## Input

All pointer input is ordinary mouse events (touch is emulated as mouse). `DragPiece` reads positions from the event, not the hardware cursor, so the gamepad's `VirtualCursor` drives every primitive by pushing the same events.

## Testing

`tests/test_runner.tscn` runs unit tests for facts, conditions, saves and migrations, every primitive's completion and self-correction, observation wording, real pointer-event dragging, and an end-to-end playthrough. In the playthrough the avatar actually walks (navigation included) from the letter to Miriam, through planting, setting the table and the Atrium, then save → title → reload, then resting into day 2 to check the sprouts and Miriam's changed dialogue.

## Known gaps and next steps

- **Headless runs log `Parameter "m" is null`** three times: Godot's dummy renderer can't store the code-built terrain and forest meshes. It is harmless and does not occur with a real renderer.
- **Tablet performance of the lush pass is unmeasured.** Every check so far has used a software renderer. Profile on baseline hardware and tune the `GroundCover.LAYERS` densities or the default for "Less scenery detail".
- **Art is partly placeholder.** KayKit and Quaternius CC0 props dress the world through `Props` and `assets/props.json`. The Quaternius foliage uses alpha-cut leaf cards, so it is more detailed than the flat-coloured custom buildings; the paid Source edition's stylized shader, or a custom toon shader, would bring them closer together. The custom hero assets named in ART_DIRECTION/ASSET_STRATEGY are still primitive-built: protagonist, Miriam and villagers, cottage shell, Chapel, Scripture figures. The KayKit hex pack's hills and mountains are map tiles with cliff sides, so distant hills stay procedural.
- **Narration** uses system text-to-speech when available. Recorded narration needs an `audio` field (the validator already checks that the file exists) and playback in `AudioService`.
- **Localization:** strings pass through `tr()` but no translation tables exist yet.
- **Performance** has only been checked on a software renderer. Profiling on baseline tablet hardware is still to do, as is evaluating mobile/web export.
- **Only two days** are authored; day 0 is the free-day template. The day definitions' `primary_activity` and `free_work` fields are validated, but nothing in the UI reads them yet (Miriam's dialogue drives the day).
- **Gamepad UI navigation** works for buttons (focus rings) and activities (virtual cursor). The map's travel buttons are reachable by focus but not tuned.
