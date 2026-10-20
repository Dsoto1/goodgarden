# Technical Specification

## Stack
- Engine: Godot 4.x
- Language: GDScript
- Presentation: stylized 3D world + 2D UI/workspace overlays as useful
- Initial target: desktop + tablet-friendly architecture; evaluate mobile/web exports after vertical slice performance testing
- Offline-first
- Single-player first

## Core Architecture
Suggested systems:
- GameState / SaveService
- WorldStateService
- Day/SeasonService
- InvitationService
- InteractionService
- DialogueService
- ActivityRunner
- ActivityDefinition resources/data
- Manipulative base components
- LearningObservationService
- JournalService
- Map/DiscoveryService
- AudioService
- AccessibilitySettings

## Scene Direction
World regions should be independently loadable/streamable scenes. Activity workspaces should be reusable scenes instantiated from data definitions. Avoid one enormous scene tree.

## Data-Driven Activity Definition
An activity should be able to declare: id, title/internal name, age/readiness tags, learning concepts, formation themes, required manipulative scene(s), instructions/narration, validation/self-correction behavior, observation events, prerequisites, world-state effects, replay rules, and optional real-world invitation.

## Persistence
Persist world facts, not only completion flags. Examples: garden plot planted with crop X on day Y; bridge railing repaired; location discovered; material presentation previously explored; NPC relationship/story flags. Version save schema from day one.

## Performance
Assume modest tablets as an eventual target: atlas/shared materials where sensible, baked/static lighting where beneficial, conservative draw calls, pooled repeated objects, simple collisions, distance culling/LOD for larger regions, and profiling before visual escalation.

## Code Quality
Small components, composition over deep inheritance, explicit signals/events, typed GDScript where it improves safety, descriptive names, no monolithic manager scripts, comments for intent/tradeoffs rather than obvious syntax.
