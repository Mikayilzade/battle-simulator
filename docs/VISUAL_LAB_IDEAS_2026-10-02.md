# Visual Lab direction — working ideas, 2026-10-02

> Status: **working direction, not final canon**.
>
> These ideas capture the user's current preference after reviewing the first playable UI.
> They are intentionally reversible. Build, review, keep what works, replace what does not.

## Why the current battle presentation is paused

The current playable battle proves the domain, AI, replay and UI integration work,
but the visual direction is not accepted. It still feels too much like a technical
tactics prototype and not enough like the intended Epohi / Civilization-like strategy
experience.

Do not spend more time polishing the existing battle screen as if it were the final
presentation. Preserve the working combat core underneath and use a separate visual
selection stand before committing to a final art direction.

## Working turn-flow direction

The current alternating-squad flow is not intuitive enough for the user.

**Working proposal for the next prototype:**

- Blue starts a side turn.
- Blue may activate its available squads in **any order**.
- Each living squad may be activated at most once during that side turn.
- The player may stop early with **End Turn / Pass Turn**.
- Then Red takes its whole side turn and may activate its available squads in any order.
- After Red ends its turn, control returns to Blue.
- No forced Blue squad -> Red squad -> Blue squad -> Red squad alternation.
- Existing per-squad hybrid action economy remains unchanged inside an activation:
  action pool at activation start equals living members.

This is a **working direction for the next playtest**, not an irreversible rule.
The scheduler/replay/AI layer will need an explicit follow-up change if this direction
is confirmed after the next playable prototype.

## New immediate goal: Visual Style Lab

Before further battle-screen polish, build a standalone **Art Direction Lab / Visual
Style Lab** inside this Godot project.

The Lab is for comparing visual directions, not for playing a battle.

Primary goals:

1. compare map/board presentation styles;
2. compare terrain rendering styles;
3. compare squad/unit presentation styles;
4. combine chosen pieces into one preview scene;
5. shortlist favorites without deleting rejected work;
6. preserve IDs so feedback can refer to exact variants;
7. make it cheap to add new reference-driven variants later if none of the first set
   is good enough.

## Lab navigation

Recommended top-level tabs:

1. **Field Styles**
2. **Terrain Library**
3. **Unit Styles**
4. **Combined Preview**
5. **Shortlist / Archive**

A single screen with side panels is also acceptable if it stays easy to browse.

## Field Styles

Show multiple complete battlefield/base-tile visual directions.

Target categories:

- 2D flat strategy map
- 2D illustrated / painted
- 2.5D isometric soft
- 2.5D chunky / boardgame-like
- faux-3D / 3D-look
- true 3D exploratory sample only if cheap enough

The logical battle grid may stay 9x7 underneath. The purpose here is to compare
presentation, camera angle, tile shape, depth, borders, shadows, scale and readability.

Each field variant must have a stable ID, for example:

- FIELD-2D-01
- FIELD-2D-02
- FIELD-25D-01
- FIELD-3D-01

The Lab should let the user switch between field styles instantly.

## Terrain Library

Prepare visual variants for at least these terrain families:

- plain / grassland
- fields / farmland
- forest
- hills
- mountains
- rough / broken ground
- rocks / blockers
- lake
- sea
- road / path

No new terrain mechanics are implied by this list. The Lab is visual only.

For each terrain family, explore more than one rendering language rather than one
final asset. Useful direction groups include:

- bright clean strategy
- muted Epohi-like
- painterly
- boardgame miniature
- chunky low-poly
- soft stylized
- semi-realistic readable

Stable IDs should make feedback easy, for example:

- TERRAIN-FOREST-25D-03
- TERRAIN-HILL-2D-06
- TERRAIN-SEA-3D-02

## Unit Style Library

Core first unit roles:

- Guard
- Striker
- Archer

Commander variations may reuse the same unit family with an extra banner, plume,
base marker or other clear distinction.

The long-term comparison target is **up to 10 variants per unit role per visual mode**:

- 2D
- 2.5D
- 3D / faux-3D

This can be produced in stages. The first pass does not need to generate all 90
combinations if quality would suffer; it should establish several genuinely different
directions first, then expand promising families toward 10 variants.

Examples of unit presentation directions:

- small grouped soldiers
- banner + figures
- icon/silhouette on a base
- miniature-boardgame figures
- chunky stylized characters
- clean strategy tokens with character art
- low-poly figurines
- painterly sprites
- compact troop formations
- commander-led squad markers

Each variant must have a stable ID, e.g.:

- UNIT-GUARD-2D-01
- UNIT-ARCHER-25D-04
- UNIT-STRIKER-3D-02

Blue/Red sides should differ by more than color where practical:
banner/base shape, trim, silhouette cue or another readable marker.

## Combined Preview

The most important Lab screen.

Let the user combine:

- one field style;
- one visual set for each terrain type;
- one Guard style;
- one Striker style;
- one Archer style;
- Blue/Red side treatment.

Render them together on a representative small battlefield.

The goal is to answer:
"Do these choices actually look coherent together?"

Useful preview states:

- normal
- selected squad
- reachable cells
- attack target
- rough/blocked terrain
- crowded units
- Blue vs Red overlap/readability

This is presentation-only. No need to run a full battle in the Lab.

## Selection, shortlist and archive

Do not delete variants just because they are not selected.

Each variant should support simple status:

- neutral
- favorite / shortlist
- archived / rejected for now
- selected for current combined preview

Persisting the selection to a tiny local config/resource is optional for the first
pass; at minimum the architecture should make it easy.

The user should be able to say things like:

- "keep FIELD-25D-04"
- "archive UNIT-GUARD-2D-02"
- "combine TERRAIN-FOREST-25D-05 with UNIT-ARCHER-25D-03"

## Asset and copyright boundary

Do not copy Civilization, Polytopia or other commercial game assets.

The first Lab should use original procedural Godot drawing, simple meshes, generated
shapes, gradients, materials and/or original temporary art.

External references may inform broad art direction later, but the repository should
contain only original or properly licensed assets.

## What NOT to do during the Lab pass

Do not:

- rebalance combat;
- add new combat mechanics;
- polish the current battle HUD;
- add audio;
- add networking;
- add campaign/progression;
- add Production/Training;
- integrate with Epohi;
- spend time on Windows export before the visual direction is accepted.

Keep the working battle implementation intact while the Lab evolves beside it.

## Review strategy

The Lab exists because visual direction is subjective and should be chosen by review,
not guessed by the implementation agent.

Expected loop:

1. build a batch of clearly different variants;
2. user reviews screenshots / live Lab;
3. favorite and archive exact IDs;
4. expand promising families;
5. if nothing is good enough, user supplies references;
6. build a second batch informed by those references;
7. only after an accepted visual pack exists, return to the main battle screen.

## Open questions intentionally deferred

These do not block the first Lab:

- exact final 2D vs 2.5D vs true 3D choice;
- final palette;
- final terrain density/detail;
- exact figure count per squad marker;
- animation style;
- final camera controls;
- final commander visual language;
- whether every terrain family needs all three dimensions/modes.

The Lab should help answer these questions instead of requiring them up front.
