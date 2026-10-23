# Roadmap

Where The Good Garden stands against the design docs (`docs/design/`), and
what comes next. Reviewed and agreed 2026-10-22. Update this file as phases
finish.

## Where we are

**The vertical slice is complete.** Every step in `VERTICAL_SLICE.md` is
built and covered by the tests: home and the letter, Miss Miriam, the bean
row (self-correcting spacing and counting), the planted bed persisting, a
second practical-life activity (setting the table), the Good Samaritan in the
Atrium, and save / quit / reload.

Beyond the slice:

- Two weeks of days, each week Monday to Sunday (see below).
- Three jobs a day; the corner note shows them compactly.
- Farm animals the child can pet (Quaternius CC0) with real CC0 sounds.
- The mill, the oven, the orchard, the pond and the sheepfold.
- The illustrated map with travel, the journal, the grown-ups page, and
  at-home invitations.
- Read-aloud, larger text for younger children, and tall panels that scroll.
- Builds for Mac, Windows, Linux, the web, Android and iPad.

| Design target | Now |
|---|---|
| 12 weeks × 5 guided days = 60 guided days | 10 guided days written (weeks 1–2) |
| 12–15 reusable activity types (`LEARNING_DESIGN.md`) | 20: spacing along a line, counting into slots, matching to outlines, sorting into bins, balance scale, sequence cards, story figures, building words, labelling pictures, measuring with units, pouring to a line, paying with coins, looking closely, continuing a pattern, fitting shapes, giving change, filling an order from a note, writing a letter, following directions on a map, sharing equally |
| 15–20 Scripture presentations at launch (`CHAPEL_ATRIUM.md`) | 7 (paused at the owner's request) |
| Regions: homestead, valley/village, farm & mill, forest/grove, Bellhaven later | Forest/grove not built; Bellhaven visible, not reachable |

## Decisions (2026-10-22)

1. **The week:** Monday to Friday are guided days (a letter and three jobs).
   Saturday is a free day (no letter; open play and free work). Sunday is a
   day of rest, with the neighbours at the Chapel. Twelve weeks give exactly
   the 60 guided days in `CURRICULUM_ROADMAP.md`.
2. **Bedtime:** the bed reminds the child of jobs still waiting, but lets
   them rest anyway. "Keep working" is the answer that starts selected
   (freedom within boundaries; no punishment).
3. **Reading comes next.** It is the largest learning gap for ages 5–10.

The jobs note is a deliberate exception to "no persistent quest clutter";
see `UI_UX.md`.

## Phase A: close out the slice (short)

- [x] Monday–Friday guided, free Saturday, Sunday rest
- [x] Bed reminds instead of blocking
- [x] Design docs updated (`CURRICULUM_ROADMAP.md`, `UI_UX.md`,
      `CONTENT_GUIDE.md`)
- [ ] Playtest the latest build with a child (`docs/PLAYTEST.md`)
- [x] Carry old saves over to the new week (save schema 2 migration)
- [x] Map labels overlapping at the largest text size

## Phase B: new activity types (reach 12)

Each new type goes into a few real days at once, so it is tried in play.

1. **Words and letters (reading).** Montessori-style:
   - letter sounds (sandpaper-letter style: trace, hear the sound)
   - [x] matching picture to word, and first sounds to letters:
     `label_pictures`, first used for Mr. Tobias's stall labels (Thursday,
     week 1; younger children match first sounds, older ones read words)
   - [x] building short words from loose letters (moveable alphabet):
     `build_word`, first used for the animals' name signs (Tuesday, week 1)
   - reading short notes and signs in the world
2. **Pouring and transferring.** Kitchen and garden: water, grain, flour.
   - [x] `pour_to_line`: pouring water for supper to a line on each glass
     (older: three quarters, half, a quarter); Thursday, week 2. The
     glasses then stand on the table.
3. **Measuring and comparing.** Lengths and heights: bean growth, cloth,
   paths.
   - [x] `measure_with_units`: measuring the bean plants with equal blocks,
     then the tallest (younger) or how much taller (older); Tuesday, week 2.
     A notched stick then stays by the row.
4. **Money and exchange.** Market stalls; honest change.
   - [x] `pay_with_coins`: buying food for supper at Mr. Tobias's stall
     (younger: count out 1-coins; older: 1, 2 and 5-coins with change, and
     a mistaken change to check honestly); Monday, week 2. The food then
     waits on the table at home.
5. **Observing and recording.** A nature journal: look closely, note what
   you see.
   - [x] `look_closely`: a magnifying glass over a bean leaf; count the
     ladybird's spots (older: and the ant's legs) and write them in the
     notebook; Friday, week 2. A ladybird then stays on the beans.

Later candidates: rotate and fit (workshop geometry), construct.

## Phase C: weeks 3–4, Stewardship & Garden ✓

Ten guided days (Saturdays free, Sundays of rest), plus the Grove behind
the chapel. Each day's main work leaves a mark in the world.

- [x] Week 3, home and garden:
  - Mon 15: collect the eggs and count them into baskets to share
    (`count_into_slots`; older: a different number on each basket)
  - Tue 16: weed the bean row (`sort_into_bins`: weeds and stones; older:
    and worms back in the soil). The weeds are gone from the row.
  - Wed 17: label Mrs. Ruth's pantry shelf (`label_pictures`: pot, cup,
    lid; older: read pot, pan, cup, lid)
  - Thu 18: a flower border in a pattern (`continue_pattern`: red, yellow;
    older: red, yellow, blue). It then blooms along the garden fence.
  - Fri 19: measure the beans again, and see how much they've grown
- [x] Week 4, the Grove (a path round the chapel's east side):
  - Mon 22: sort the fallen leaves by shape (oak, maple; older: and round)
  - Tue 23: nature-trail signs (`build_word`: log, bug, web; older: and
    fox, without the letters shown). The signs stand along the trail.
  - Wed 24: plant acorns in a row (spacing, then counting into holes);
    seedlings come up two days later
  - Thu 25: a stepping-stone path in a pattern (big, small; older: big, big,
    small). The stones stay on the path.
  - Fri 26: fill the bird feeders to the line (`pour_to_line` with seed;
    older: half, full, a quarter). Birds come to eat.

Not yet: brushing the horse.

## Phase D: weeks 5–6, Truth & Workshop/Market ✓

A new neighbour, **Mr. Amos the carpenter**, works in the workshop by the
square (he joins the others at the Chapel on Sundays). Three new activity
types: `fit_shapes` (geometric insets: turn a shape to fit its outline),
`give_change` (minding a stall: count change on from the price; an honest
moment when a customer overpays) and `fill_order` (read a neighbour's note
or list and fetch just what it says).

- [x] Week 5, the workshop:
  - Mon 29: meet Mr. Amos; sort wooden shapes (older: tell squares from
    rectangles). The sorted boxes then sit on his bench.
  - Tue 30: mend Mrs. Ruth's window (`fit_shapes`: rectangles turned to fit;
    older: pairs of triangles make squares). The window waits by her door.
  - Wed 31: read Mr. Amos's note and fetch what he needs (`fill_order`;
    older: no pictures on the note)
  - Thu 32: line the planks up, shortest to longest (seriation, with
    `sequence_cards`)
  - Fri 33: build a birdhouse (`fit_shapes`: a roof of two triangles). It
    goes up in Miss Miriam's garden, and a bird moves in the next day.
- [x] Week 6, the market:
  - Mon 36: sell eggs with Mrs. Ruth (`give_change`: paid with a 5, counting
    on; older: paid with 10s, change in 1s, 2s and 5s)
  - Tue 37: honest scales with Mr. Tobias (`balance_scale`)
  - Wed 38: Miss Miriam's shopping list (`fill_order`)
  - Thu 39: count the takings in piles of five (older: tens)
  - Fri 40: mind the bread stall alone; a customer overpays and the child
    checks (`give_change` with `mistaken_pay`)

## Phase E: weeks 7–12 ✓

The whole first season is written: 60 guided days, Saturdays free and
Sundays of rest, ending in the Harvest Supper. Three new activity types:
`compose_letter` (write by choosing a word for each coloured space; the
child's own letter, never one right answer), `follow_directions` (a
squared map of the valley: "Go 3 squares east") and `share_equally`
(division by dealing out, with a "left over" bowl for older children).
Each day's work starts at a **job spot** (`content/world/job_spots.json`),
so new days need no code.

- [x] Weeks 7–8, Compassion & Community: Mrs. Ruth's grandson Sam's map
  of the valley; a letter to Sam in Bellhaven; sharing rolls with families
  from over the hills; words for the new signpost by the bridge (it then
  stands there); packing a cart for Bellhaven and planning its way; seeds
  for every neighbour; a get-well card for Mr. Amos, and tidying for him;
  welcoming travellers.
- [x] Weeks 9–10, Forgiveness & Cooperation: a storm; mending the
  sheepfold fence; finding the lost lamb with the map (she waits in the
  grove); helping Mrs. Ruth write a sorry note, and replanting Miss
  Miriam's border together; patching the coop roof; then a project with
  Mr. Amos and Mr. Tobias: plan, fetch, share the work, paint, and arrange
  long tables in the square.
- [x] Weeks 11–12, Gratitude & Harvest: picking the beans planted on day 1;
  apples shared among the houses; invitations; counting out food; bunting
  across the square; weighing flour, setting the long table, pouring,
  sharing the pies in quarters; and on day 82 the Harvest Supper, with
  everyone (Sam too) at the table, and the child's own thank-you.

## The wider world ✓

The places on the concept map beyond the valley, each built on a level site
cut into the real landscape where the map puts it, and reached from the
map's new **wider world** view once it opens (`regions.json` `open_when`).
Each has someone to meet and two jobs (free work, any day after it opens):

| Place | Opens | Who | Work |
|---|---|---|---|
| The Wilderness (by the great waterfall, west) | day 22 | (deer) | sort leaves by shape; follow the trail map to the waterfall |
| The Farmlands (south) | day 36 | Mrs. Hannah | stand sheaves in stooks (groups of); share hay among the cows |
| The Lake (south-east hills) | day 43 | Mr. Finn | count the catch into baskets; who lives in the lake |
| Bellhaven (the city, north) | day 50 | Mrs. Greta | count coins in fives; mind her stall, giving change |
| The Monastery (east hill) | day 57 | Brother Elias | copy a page; follow the oldest map across the land |
| The Coast and harbour (east, where the river meets the sea) | day 64 | Captain Mara | load the ship's stores from a list; sort the catch |
| The Mountains (north-east) | day 71 | Mr. Silas | mark the trail with a pattern of stones; climb the trail map to the peak |

The landscape now has a sea beyond the river's mouth and a lake in the
south-eastern hills. Next for these places: story days that visit them
(a second season), interiors (the library, the scriptorium, the ship), and
walking roads between them.

## Alongside, when it fits

- **Chapel library:** more presentations toward 15–20, when the owner
  resumes it.
- **Identity art:** custom protagonist and neighbours (`ART_DIRECTION.md`
  "custom first").
- **Sound:** a CC0 horse voice when one with a clear licence turns up.
- **Tablets:** performance testing on real devices.
- **Translation:** prepare the text for other languages.
- **Review before release:** theological and educational review of all
  Scripture and teaching content, and a child-privacy review
  (`CHRISTIAN_FOUNDATIONS.md`, `PARENT_TEACHER.md`).
