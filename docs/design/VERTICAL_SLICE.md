# Vertical Slice

## Purpose
Prove the emotional and technical core before building 60 days of content.

## Playable Space
- Child's Home exterior/interior-lite as appropriate
- Garden
- Village path with a few visible buildings/props
- Chapel/Atrium
- distant Bellhaven silhouette/view if composition allows

## Characters
- Player child avatar
- Miriam as primary NPC
- 1–2 ambient villagers
- a few ambient animals

## Required Flow
1. Begin at Home.
2. Receive/read an Invitation from Miriam.
3. Walk to Garden.
4. Speak with Miriam.
5. Enter gardening Activity Mode.
6. Complete a tactile seed/spacing/counting activity with self-correction.
7. Return to world and see the planted bed persist.
8. Free exploration.
9. Enter Chapel/Atrium.
10. Select one Scripture material set (recommended prototype: Good Samaritan).
11. Hear/read presentation, manipulate/retell, return materials without score.
12. Save, quit, reload; world state remains correct.

## Second Activity
Include one small practical-life activity (e.g. table setting, sorting garden tools, simple measuring/pouring) to prove ActivityRunner reuse rather than hard-coding the gardening scene.

## Acceptance Criteria
- Movement/camera comfortable for a young child.
- Interaction readable without HUD clutter.
- Activity transitions feel natural.
- At least two activities share reusable framework code.
- World persistence works across reload.
- Chapel experience visibly/aurally feels different from task gameplay.
- Stable performance on selected baseline hardware.
- No architecture decision blocks later Bellhaven/region expansion.
