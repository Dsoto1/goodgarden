# Content Pipeline

## Goal
Writers/educators/designers should be able to create new days and activities without modifying engine code for ordinary content.

## Layers
1. Reusable interaction/manipulative system.
2. Activity definition (data/resource).
3. Narrative wrapper: character, need, dialogue, location.
4. Learning metadata and observation hooks.
5. World-state result.
6. Optional real-world invitation.
7. Editorial/educational/theological review as appropriate.

## Day Definition
A day can reference an Invitation, NPC/world changes, one primary activity, optional secondary/free-work suggestions, Chapel availability/presentation, and end-of-day conditions. Days should support branching/contextual variants without becoming giant scripts.

## Validation
Automated checks should detect missing IDs, broken resource references, impossible prerequisites, inaccessible world effects, unlocalized strings, missing narration references, and untracked third-party assets.
