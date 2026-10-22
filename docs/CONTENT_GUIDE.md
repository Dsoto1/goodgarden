# Content Guide

Writers, educators and designers can add days, letters, conversations and activities by editing JSON in `content/`. No engine code changes are needed for ordinary content. After editing, run the validator:

```sh
godot --headless --path . res://tools/validate_content.tscn
```

Every file has an `"id"`. All text is plain English for now and passes through `tr()`, so it can be translated later.

## Days — `content/days/day_NNN.json`

```json
{
	"id": "day_002", "day": 2, "week": 1, "arc": "Creation & Home",
	"invitation": "inv_day_002",
	"npcs": {"miriam": "garden_miriam"},
	"primary_activity": "garden_bean_row",
	"free_work": ["home_set_table"],
	"chapel": ["good_samaritan"]
}
```

`npcs` maps a character to an **anchor** placed by a region (e.g. `garden_miriam`, `home_spawn`, `village_plaza`, `chapel_door`, `village_overlook`). Leave a character out and they stay away that day. Day `0` is the template for days past the written content.

## Invitations — `content/invitations/*.json`

`{"id", "from", "body", "signature", "suggests"?, "summary", "done"?, "tasks"?}`. `body` may contain blank lines. A day's letter waits by the cottage door until it is read.

`tasks` is the day's jobs, three at most (a working day has three: the letter's main work and two small everyday ones). Each is `{"text", "activity"}` (done when that activity was finished today) or `{"text", "done_when"}` (conditions, same format as dialogue `when`). Useful facts: `home.table_set_day`, `home.hens_fed_day`, `npc.<id>.greeted_day`, `animals.<kind>.stroked_day` (lamb, sheep, cat, dog, cow, horse, pig), each with `"is_today": true`; or `[{"fact": "npc.ruth.card", "equals": "given"}]` for work that ends with a conversation. Stories in the Chapel are never jobs: quiet time is the child's own.

The jobs are listed under the letter and in the corner note, each ticked as it is done. When all are done the note turns green with `done` (a short thank-you) and the child is told the day's work is finished. A letter without `tasks` has one job: its `summary`, done when the `suggests` activity was finished today. The day of rest has none.

## Real-world invitations — `content/real_world/*.json`

`{"id", "text", "checkable"}`. These appear in the Journal after an activity that names them. Set `"checkable": false` for faith-related prompts, so there is nothing to tick.

## Dialogue — `content/dialogue/*.json`

```json
{
	"id": "miriam", "speaker": "miriam",
	"entries": [
		{"when": [{"fact": "garden.bed_1", "exists": true}, {"day_at_least": 2}], "start": "growing"},
		{"when": [], "start": "greet"}
	],
	"nodes": {
		"greet": {"text": "...", "next": "offer"},
		"offer": {"text": "...", "choices": [
			{"text": "Yes, please! Let's plant.", "next": "go", "actions": [{"op": "start_activity", "id": "garden_bean_row"}]},
			{"text": "Not yet, thank you.", "next": "later"}
		]}
	}
}
```

A day's `"npcs"` can send a neighbour somewhere for the day (`"ruth": "sheepfold_ruth"`): they wait at that anchor instead of their usual spot. The first entry whose `when` conditions all hold is used. The child's Next button speaks for them: it greets the grown-up ("Hello, Miriam!") the first time they meet that day and says "Goodbye, Miriam!" on the last line. Give a node a `"reply"` when the child should answer something specific, e.g. `"reply": "You're welcome, Ruth!"` after a thank-you (a greeting is added in front if it's their first meeting that day). Node and choice `actions` can `start_activity` (it starts after the conversation closes) and `set_fact` / `increment` / `clear`. Characters' display names live in `content/world/characters.json`.

### Conditions (used everywhere)

| Condition | Meaning |
|---|---|
| `{"fact": "k", "exists": true}` | fact is (not) present |
| `{"fact": "k", "equals": v}` | fact equals a value |
| `{"fact": "k", "at_least": 2}` | numeric fact ≥ 2 |
| `{"fact": "k", "is_today": true}` | fact holds today's day number |
| `{"day": 3}` / `{"day_at_least": 2}` | current day |
| `{"any": [...]}` / `{"not": {...}}` | combine |

## Activities — `content/activities/*.json`

| Field | Purpose |
|---|---|
| `id`, `title` | identity; `title` appears on the grown-ups' page |
| `mode` | `"task"` or `"reflection"` (Chapel/Atrium: no hints, no restart, no scoring, quiet styling) |
| `location` | region id |
| `surface` | `soil_bed`, `wood_table` or `atrium_felt` |
| `readiness`, `concepts`, `formation_themes` | learning metadata for adults and future readiness tuning |
| `prerequisites` | conditions for the activity to be offered |
| `intro`, `outro` | lines `{"speaker"?, "text", "button"?}` shown on the prompt card |
| `steps` | ordered steps, each `{"id", "primitive", "prompt", "hint"?, "feedback"?, ...config}` |
| `world_effects` | `{"op": "set"/"increment"/"clear", "fact", "value"}`; values may use `$day` and `$<step_id>.<result key>` |
| `replay` | `"free"` (repeat by choice) or `"once"` |
| `real_world_invitation` | id from `content/real_world` |
| `journal_line` | child-voice sentence added to the Journal |
| `unavailable_text` | gentle line if the child tries it when it isn't offered |
| `review_status`, `source` | editorial tracking, e.g. Scripture reference |

### Older children

Hands-on activities serve ages 5 to 10 through a grown-up's **Work level** setting (in "For grown-ups"). An activity may carry an `"older"` object (`intro`, `outro`, `journal_line`) and each step its own `"older"` settings, laid over the usual ones for older children: bigger numbers, no counting dots (`"show_dimples": false`), more kinds to sort, a heavier stone, more loaves. Keep the same work and story, only asking a little more. Bible stories are the same at both levels.

```json
{"id": "share_hay", "older": {"slots": 4, "show_dimples": false, "prompt": "Share these twelve bundles fairly between the four troughs."}, ...}
```

### Primitive configuration

**`space_along_line`**: `markers`, `stick_length`, `tolerance`, optional `row_y`, `row_from`, `row_to`. Result: `count`, `positions` (0–1 along the row). Feedback keys: `placed_all`, `crowded`, `far`, `all_good`.

**`count_into_slots`**: `per_slot` or `counts`, `slots` or `slots_from` (an earlier step's `positions`), `piece` (`bean_seed`, `bread_roll`, `water_drop`, `hay`, ...), `container` (`hole`, `plant`, `basket`, `trough`), `supply_label`, `supply_color`, `spare`, `show_dimples`. Result: `slots`, `per_slot`, `pieces`. Feedback: `full`, `all_good`.

**`sort_into_bins`**: `pieces: [{"kind", "count"}]`, `bins: [{"kind", "label", "look": "sack"|"basket"|"pond"|"meadow"|"sky", "pos", "group"?}]`, `pile`, `piece_size`. With `groups: {kind: group}` a bin takes every kind in its `group` (pond creatures into the pond) instead of one kind. Result: `sorted`. Feedback: `mismatch`, `all_good`.

**`sequence_cards`**: `cards: [kind, ...]` in the right order, optional `labels` (a caption on each card) and `show_dots` (dots under each number, on by default). Cards start shuffled; once every place is filled, cards in the wrong place slide back. Kinds: `card_seed`, `card_sprout`, `card_sapling`, `card_blossom`, `card_apples`. Result: `cards`, `tries`. Feedback: `out_of_order`, `all_good`.

**`balance_scale`**: `weight` (in small scoops), `scoops: [{"kind", "weight", "count"}]`, `weight_label`, `supply_label`. Result: `scoops`. Feedback: `heavy`, `all_good`.

**`match_to_outline`**: `slots: [{"kind", "pos": [x, y]}]`, optional `mats`, `box`, `box_label`, `tray`, or `pieces_from_previous: true` to reuse the prior step's pieces. Kinds: `plate`, `bowl_small`, `cup`, `fork`, `spoon`, `knife`, `napkin`, `coin`, `loaf_round`, `loaf_long`, `bread_roll`, `figure:<id>`. `oven: [x, y, w, h]` draws an oven mouth behind the outlines; `card: [x, y, w, h]` an open folded card (with kinds `pressed_daisy`, `pressed_violet`, `pressed_leaf`, `heart`). Result: `placed`. Feedback: `mismatch`, `all_good`.

**`story_figures`**: `places`, `road`, `figures` (`{"id", "label", "color", "shape"?: "donkey"|"building", "accent"?}`), `box`, `segments` (`{"text", "reveal": [ids], "show": {id: {"pos", "lying"}}}`), `wonderings`, `reference`. Result: `retell_seconds`. Follow it with a `match_to_outline` step using `pieces_from_previous` so the child puts the material away.

Positions are in **board units** (1000 × 560); the workspace scales the board to the screen.

## Atrium shelf — `content/world/atrium_shelf.json`

`{"items": [{"activity", "label", "tray_color"}]}`. Each item adds a tray to the Chapel shelf. Only `reflection` activities may be listed.

## Principles to keep (from DESIGN_CONSTITUTION.md)

- Concrete before abstract: the child handles the pegs and seeds before any numbers are named.
- Feedback is environmental ("the stick lies over a peg"), never "wrong".
- Faith is never currency: no scores, streaks or rewards on prayer or Scripture, and no observation that infers spiritual growth.
- Real-world invitations are optional and never penalized.
- Manners and respect for elders run through everything, shown rather than preached:
  - The child greets grown-ups, says please and thank you, and answers thanks with "You're welcome".
  - Grown-ups are named with a title everywhere the child hears or says it: Miss Miriam, Mr. Tobias, Mrs. Ruth (the display names in `characters.json`). The grown-ups use the titles for each other too.
  - The child's choices are always polite, including saying no ("Not yet, thank you.").
  - Grown-ups model the same manners: they ask with "would you please", thank the child, and speak to them kindly.
  - Elders are spoken of with warmth and respect: their stories, their work and their wisdom are worth listening to.
  - Never a rude or cheeky option, and no lecture about manners.
