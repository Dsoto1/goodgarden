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

The days run in weeks, and day 1 is a Monday. **Monday to Friday** each have a letter with three jobs. **Saturday** is a free day: a day file with no `invitation`, for open play and free work. **Sunday** is the day of rest: a short letter and no jobs, with the neighbours at the Chapel (`chapel_miriam`, `chapel_tobias`, `chapel_ruth`, `chapel_amos`); Sundays past the written days do the same on their own. Twelve weeks make the season's 60 guided days.

## Invitations — `content/invitations/*.json`

`{"id", "from", "body", "signature", "suggests"?, "summary", "done"?, "tasks"?}`. `body` may contain blank lines. A day's letter waits by the cottage door until it is read.

`tasks` is the day's jobs, three at most (a working day has three: the letter's main work and two small everyday ones). Each has a short `text` (two to four words: it is what the corner note shows), a `where` (shown after it in the letter, e.g. "in the sty by the mill"), an `icon` (see `TodaysWork.ICONS`), and either an `activity` (done when that activity was finished today) or `done_when` (conditions, same format as dialogue `when`). Useful facts: `home.table_set_day`, `home.hens_fed_day`, `npc.<id>.greeted_day`, `animals.<kind>.petted_day` (lamb, sheep, cat, dog, cow, horse, pig), each with `"is_today": true`; or `[{"fact": "npc.ruth.card", "equals": "given"}]` for work that ends with a conversation. Stories in the Chapel are never jobs: quiet time is the child's own.

The jobs are listed in full under the letter. The corner note is compact: one picture per job, which gets a green tick when done, and only the next job in words. When all are done the note turns green with `done` (a short thank-you) and the child is told the day's work is finished. A letter without `tasks` has one job: its `summary`, done when the `suggests` activity was finished today. Saturday and Sunday have none. The bed reminds the child of jobs still waiting, but lets them rest anyway.

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
| `{"weekday": "sunday"}` | day of the week (`"monday"` … `"sunday"`) |
| `{"can_start": "garden_weed"}` | the activity could be started now (its prerequisites hold, and it is not done if it runs once) |
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

**`build_word`** (reading, after the Montessori moveable alphabet): `words` (short words spelled sound by sound, e.g. `["hen", "cat", "pig"]`), `pictures` (`{word: icon}`; icons `hen`, `cat`, `pig`, `dog`, `cow`, `sheep`, ...), `show_letters` (faint letters in each place to match; set `false` for children ready to listen alone), `extra_letters` (letters in the box that aren't needed). Tapping the picture says the word; tapping a letter says its sound; vowels are blue, consonants red. A letter only settles where its sound belongs. Each finished word is sounded out and laid on a shelf. Result: `words`. Feedback: `wrong`, `word_done`, `all_good` (`{word}` becomes the word).

**`label_pictures`** (reading, after the Montessori picture-and-label cards): `items` (the names, e.g. `["bun", "jam", "egg"]`), `pictures` (`{item: icon}`; icons include `bun`, `jam`, `egg`, `nut`, `fig` and the animals), `mode` (`"first_sound"`: each label is the letter of the name's first sound, for younger children; `"word"`: each label is the written word), `extra` (labels that name no picture here). Tapping a picture says its name; tapping a label says its sound, or a word's sounds one by one for the child to blend. A label only settles under the picture it names. Result: `labels`. Feedback: `wrong`, `all_good`.

**`measure_with_units`** (measuring and comparing): `heights` (each plant's height in blocks), `unit` (block size in board units, default 40), `question` (`"tallest"`: tap the tallest plant; `"difference"`: choose how many blocks taller the tallest is than the shortest), `spare`. The child stacks equal blocks beside each plant until the stack is as tall; a block that would make it taller won't stay, and each finished stack shows its count. Result: `heights`, `tallest` (index), `difference`. Feedback: `too_tall`, `measured`, `wrong_tallest`, `wrong_difference`, `all_good` (`{n}` becomes a count).

**`pour_to_line`** (practical life: pouring): `lines` (a fill line per glass, 0–1 of its height), `labels` (optional words under the glasses, e.g. "half"), `tolerance` (default 0.06), `rate` (how fast the jug pours, glass-heights per second), `liquid` (`water`, `milk`, `grain`). Holding the jug over a glass pours; letting go stops. A glass poured past its line is too full: tapping it pours it back. Result: `glasses`, `pour_backs`. Feedback: `too_full`, `not_yet`, `all_good`.

**`pay_with_coins`** (money): `buy` (`[{"item", "price", "icon"?}]`), `purse` (coin values; default enough 1-coins), `mistaken_change` (on the last purchase the shopkeeper gives one coin too many and asks the child to check it: a moment to practise honesty, thanked but never scored). Coins go on the dish, then Pay; too little is counted back, too much comes back as change. Result: `bought`, `spent`, `honest`. Feedback: `short`, `change`, `paid`, `honest`, `all_good` (`{n}`, `{item}`).

**`look_closely`** (observing and recording): `spots` (the ladybird's spots), `questions` (`[{"ask", "about": "spots"|"legs", "choices": [int]}]`). A magnifying glass shows the picture close up wherever it is moved; each right count is written into the nature notebook on the board. Result: `notes` (`[{"about", "count"}]`). Feedback: `look_again`, `noted`, `all_good`.

**`continue_pattern`** (patterns): `unit` (one repeat, e.g. `["flower_red", "flower_yellow"]`), `length` (places in the row, default 10), `given` (places already set, default one unit), `names` (`{kind: word}`, what each piece is called aloud), `look` (`"border"` soil, or `"path"`). A piece only settles where it continues the pattern; "Show me" says the pattern aloud up to the next empty place. Pieces so far: `flower_red`, `flower_yellow`, `flower_blue`, `stone_big`, `stone_small`. Result: `unit`, `length`. Feedback: `wrong` (`{pattern}` is filled in), `all_good`.

**`fit_shapes`** (geometric insets, rotate and fit): `shapes` (`[{"kind", "pos", "turn": 0..3, "size"?}]`, the outlines; `turn` is quarter turns clockwise, and two triangles may share a square), `size` (default piece size), `spare` (shapes that fit nowhere), `picture` (`"window"`, `"birdhouse"`, `"floor"`). Tapping a piece turns it; it settles only in the outline of the same shape turned the same way (squares and circles fit any way round, rectangles either way up). Shapes: `shape_square`, `shape_rect`, `shape_triangle` (right angle at the bottom left when `turn` is 0), `shape_semicircle`, `shape_circle`. Result: `shapes`, `turns`. Feedback: `turn_it`, `wrong_shape`, `all_good`.

**`give_change`** (minding a stall): `sales` (`[{"item", "price", "paid": [coins], "icon"?}]`), `cash` (coins in the cash box), `mistaken_pay` (on the last sale the customer pays one coin too many; the child is asked to check, never scored). The child counts change onto the counter and presses Give change; the customer says what is missing or hands back the extra. `prompt` may use `{item}`, `{price}`, `{paid}`. Result: `sales`, `honest`. Feedback: `short`, `too_much`, `right`, `honest`, `all_good` (`{n}` filled in).

**`fill_order`** (reading in context): `order` (`[{"item": kind, "count", "word"?, "words"?}]`, written on the note as "3 nails"), `pictures` (little pictures beside the lines; default true), `extra` (things on the shelf the note doesn't ask for), `spare`, `note_title`, `note_from`, `basket_label`. Tapping a line reads it aloud; Done checks the basket line by line. Result: `order`. Feedback: `missing`, `too_many`, `not_on_note`, `all_good`.

**`compose_letter`** (writing): `lines` (the letter, with blanks written `{key}`), `choices` (`{key: [word | {"word", "icon"}]}`), `signature`. Each blank and its cards share a colour; a card fits only a blank of its colour, and a new choice replaces the old one. There is no single right answer. When every blank is filled the letter is read back, and "Send it" finishes. Result: `words` (`{key: word}`), `text` (the whole letter; save it with a world effect such as `"value": "$letter.text"`). Feedback: `wrong_place`, `read_back`, `all_good`.

**`follow_directions`** (maps and direction): `grid` (`[cols, rows]`), `places` (`[{"icon", "at": [c, r], "name"}]`), `start`, `steps` (`[{"dir": "north"|"south"|"east"|"west", "n"}]`), `arrows` (an arrow and dots with each direction; default true). North is up. The walker stays only where the direction ends. Result: `steps`, `end`. Feedback: `wrong_way`, `count_again`, `arrived`, `all_good` (`{place}` filled in).

**`share_equally`** (division): `piece`, `total`, `plates`, `names` (under each plate), `look` (`"basket"` or `"plate"`), `leftover` (a "left over" bowl, for shares that aren't even). Nothing says how many each: the child deals them out. "Done" checks the pile is shared, the plates match, and the bowl couldn't go round once more. Result: `each`, `left`. Feedback: `not_shared`, `not_equal`, `share_more`, `all_good` (`{n}`, `{left}`).

### Where work starts: job spots

`content/world/job_spots.json` lists where each day's work is started in the world: `{"region", "at": [x, y, z] (region-local), "prompt", "activity", "from_day", "until_day"? (default: that week's Saturday), "look": "crate"|"basket"|"table"|"none", "conditions"?}`. The little prop shows from `from_day` to `until_day`; the prompt only while the activity can be started (the condition `{"can_start": "activity_id"}`, which any condition list may use).

Answer buttons from a step (numbers to choose) start with none selected, so no answer looks suggested; a single main button (Pay, Continue) starts selected.

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
