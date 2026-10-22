# UI / UX

## Principle
The world is the child's main menu. Do not expose Math / Reading / Science / Bible as the primary navigation.

## Exploration HUD
Keep minimal:
- contextual interaction prompt
- subtle current Invitation/Journal access
- Map access after unlocked
- optional accessibility/help control

Avoid persistent quest clutter, minimap overload, currencies, XP bars, streaks, and notification badges.

## Camera Modes
- Exploration: elevated three-quarter third-person, controlled follow.
- Conversation: gentle contextual framing.
- Activity: close-up work surface.
- Chapel/Atrium: intimate tabletop/presentation framing.
- Map: illustrated overhead view, after the concept art's "World Map (Fast Travel)". `MapPanel` renders the real valley from high above (a SubViewport sharing the world), warmed and edged like parchment, so it always matches the world. Each place has a picture card standing where it really is (tap to travel if visited, "?" if not, Bellhaven far away), landmarks have small badges (hold to hear their names), and a marker shows where the child is.

## Input
Design interaction abstraction for mouse, touch, keyboard/gamepad. Touch targets must be generous. Dragging should include snap tolerance and undo/reset where appropriate.

## Reading Support
Optional read-aloud, highlighted text, adjustable text size, reduced text density, repeat narration, and icon support without infantilizing older children.

The youngest players (5) are beginning readers, so nothing may depend on reading:

- Read-aloud is on by default. Every line, question, letter, journal page and at-home invitation is spoken, and questions are read out with their answers.
- Every button can be heard: hold it for a moment (touch), rest the mouse on it, or move to it with keys or a gamepad (`SpokenButton`). A long hold only speaks; it never presses.
- Buttons carry a picture beside their words (`UiStyle.button(text, primary, icon)`; icons in `Icon.draw`): a tick for yes, an arrow back for "not yet", a speaker for "Hear it".
- The safe answer starts selected on every question (`ConfirmCard`), and leaving an activity or the game asks first.
- Choices are findable without reading: story trays and book covers carry pictures, and the prompt for whatever is in reach is spoken once the child pauses by it.
- Small pieces can be picked up from a little around them (`DragPiece.MIN_TOUCH`), and a tap that wobbles doesn't move a piece.
- Lines for children stay short: one idea per sentence, about 20 words at most, everyday words (a Bible word such as "sheepfold" or "leaven" is explained the first time).
