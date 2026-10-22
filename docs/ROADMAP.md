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
| 12–15 reusable activity types (`LEARNING_DESIGN.md`) | 10: spacing along a line, counting into slots, matching to outlines, sorting into bins, balance scale, sequence cards, story figures, building words, labelling pictures, measuring with units |
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
3. **Measuring and comparing.** Lengths and heights: bean growth, cloth,
   paths.
   - [x] `measure_with_units`: measuring the bean plants with equal blocks,
     then the tallest (younger) or how much taller (older); Tuesday, week 2.
     A notched stick then stays by the row.
4. **Money and exchange.** Market stalls; honest change.
5. **Observing and recording.** A nature journal: look closely, note what
   you see.

Later candidates: rotate and fit (workshop geometry), construct.

## Phase C: weeks 3–4, Stewardship & Garden

Ten guided days, plus the forest/grove region:

- animal care (collecting eggs, brushing the horse)
- measuring how tall the beans grow
- patterns in the garden
- the first reading work in context: seed labels, notes from neighbours

## Phase D: weeks 5–6, Truth & Workshop/Market

- money and honest exchange at the stalls
- shapes and measuring in the workshop
- reading signs and notes

## Phase E: weeks 7–12

- **Weeks 7–8:** the road to Bellhaven, sharing, maps, letters.
- **Weeks 9–10:** multi-step community projects, forgiveness and
  cooperation.
- **Weeks 11–12:** the harvest celebration. The beans, orchard, bread and
  animals come together in a shared supper with the neighbours. The beans
  keep growing until then.

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
