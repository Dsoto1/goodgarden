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
| Asset normalization | `Props` + `assets/props.json` | Imported models placed by id with scale, pivot offset and collision from data. |
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
| `story_figures` | story manipulation and retelling | none by design: no checks, timers or score | Good Samaritan |

Steps never write world state. They emit `completed(result)`, and the runner turns results into facts through the definition's `world_effects`, e.g. `"positions": "$space_holes.positions"`. Regions read facts back and rebuild themselves in `sync_with_world()`, which is how the planted row survives reloads and grows over days.

Every step runs on a 1000×560 design-unit board that the workspace scales to fit the screen, so primitives never deal with resolution. Snap tolerance comes from settings ("Easier dragging") in screen pixels and is converted to board units.

## World

- **Regions** (`scripts/world/regions/*.gd`) are independent scenes placed by `content/world/regions.json`. Each builds its geometry in local space, publishes **anchors** (spawn points, NPC spots), **discovery zones**, **interior zones** (which hide the roof and front wall and set the mood) and **camera zones** (e.g. the Bellhaven vista). Streaming regions by distance later only changes how `World` loads them.
- **Navigation:** `World` bakes a navigation mesh at runtime from the static colliders (about half a second), so tap-to-walk goes through doors and gates. Characters use their own physics layer and are left out of the bake.
- **Camera:** `CameraRig` follows at a fixed elevated three-quarter angle. Zones and focus requests reframe it (conversation, activity close-up, chapel, vista); with reduced motion it cuts instead of gliding.
- **Mood:** `World.set_mood()` tweens light and ambience between outdoor, home and chapel, and quiets the HUD in the chapel.

## Input

All pointer input is ordinary mouse events (touch is emulated as mouse). `DragPiece` reads positions from the event, not the hardware cursor, so the gamepad's `VirtualCursor` drives every primitive by pushing the same events.

## Testing

`tests/test_runner.tscn` runs unit tests for facts, conditions, saves and migrations, every primitive's completion and self-correction, observation wording, real pointer-event dragging, and an end-to-end playthrough. In the playthrough the avatar actually walks (navigation included) from the letter to Miriam, through planting, setting the table and the Atrium, then save → title → reload, then resting into day 2 to check the sprouts and Miriam's changed dialogue.

## Known gaps and next steps

- **Art is partly placeholder.** KayKit CC0 props dress the world through `Props` and `assets/props.json`. The custom hero assets named in ART_DIRECTION/ASSET_STRATEGY are still primitive-built: protagonist, Miriam and villagers, cottage shell, Chapel, Scripture figures. The KayKit hex pack's hills and mountains are map tiles with cliff sides, so distant hills stay procedural.
- **Narration** uses system text-to-speech when available. Recorded narration needs an `audio` field (the validator already checks that the file exists) and playback in `AudioService`.
- **Localization:** strings pass through `tr()` but no translation tables exist yet.
- **Performance** has only been checked on a software renderer. Profiling on baseline tablet hardware is still to do, as is evaluating mobile/web export.
- **Only two days** are authored; day 0 is the free-day template. The day definitions' `primary_activity` and `free_work` fields are validated, but nothing in the UI reads them yet (Miriam's dialogue drives the day).
- **Gamepad UI navigation** works for buttons (focus rings) and activities (virtual cursor). The map's travel buttons are reachable by focus but not tuned.
