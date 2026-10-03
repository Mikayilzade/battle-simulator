# Visual Rulebook — Stylized Isometric Fantasy Miniature World
Date: 2026-10-03

Status: **active working visual direction**
Priority: **HIGH**
Applies to: Battle Simulator Visual Style Lab first, later reusable for Epohi visual exploration.

This document translates the user's latest visual preference into an implementation
rulebook. It is intentionally detailed so future agents do not substitute an unrelated
"nice-looking strategy style" for the specific direction requested.

This is NOT permission to copy any commercial game's assets, UI, characters, map,
textures, icons, composition, or proprietary visual identity. The reference is used
only to define broad visual principles.

---

# 1. Core target in one sentence

Build toward a **stylized hand-painted / sprite-like isometric 2.5D fantasy strategy
miniature world** where terrain looks like actual terrain, units look like tiny living
people, improvements look like places where activity happens, and the map remains
immediately readable as a strategy board.

The target feeling is:

> "A small living fantasy world viewed from above at an angle — cozy, detailed,
> handcrafted and readable — not a spreadsheet, not abstract tokens, and not realistic
> 3D."

---

# 2. What the user reacted positively to

The reference appealed to the user because several qualities appeared together.

## 2.1 A living miniature world

The scene reads as a location rather than a board:
- trees form real forest mass;
- logs, paths, work areas and structures imply activity;
- rock faces and terrain changes have physical depth;
- people are visibly present in the landscape;
- the world looks inhabited even before reading UI.

Epohi / Battle Simulator should gradually create the same *category of feeling*:
the player should feel they are looking at a tiny civilization/world.

## 2.2 Human figures instead of abstract counters

The user prefers:
- little people,
- small troop groups,
- visible workers,
- visible warriors,
- visible archers,
- recognizable tools/weapons,
over:
- circles,
- diamonds,
- letters such as G/S/A,
- flat faction tokens,
- debug-style markers.

## 2.3 Rich but controlled detail

The reference contains many details but still reads clearly.

Target:
- enough detail to reward looking closely;
- large shapes remain understandable at normal zoom;
- terrain class is obvious before decorative details;
- units remain visible against terrain;
- selection/route/target overlays remain legible.

Avoid:
- decoration that hides gameplay;
- excessive micro-texture;
- clutter on every tile;
- forests that swallow unit silhouettes;
- giant UI panels that cover the world.

## 2.4 Soft fantasy rather than harsh realism

Desired:
- inviting,
- warm,
- stylized,
- painterly,
- slightly storybook-like,
- believable materials without photorealism.

Undesired:
- photorealistic PBR battlefield;
- hard military realism;
- plastic toy rendering;
- neon mobile-game gloss;
- flat vector corporate graphics.

---

# 3. Perspective and camera rules

## 3.1 Primary direction: 2.5D isometric / 3-quarter top-down

The strongest current preference is a **2.5D isometric or near-isometric view**.

The camera should communicate depth while preserving tactical readability.

Target characteristics:
- mostly orthographic feeling;
- top surfaces remain visible;
- vertical objects can rise above tiles;
- near/far ordering feels natural;
- the grid can still be understood;
- silhouettes do not overlap so heavily that tile ownership is unclear.

## 3.2 Do not force mathematically perfect isometry

A strict 30-degree mathematical isometric projection is not required.

A slightly more top-down angle is acceptable if it improves:
- unit readability;
- terrain recognition;
- touch/click targeting;
- visible movement paths.

## 3.3 Comparison modes in the Visual Lab

The Lab may still contain:
- 2D,
- 2.5D,
- faux-3D / lightweight 3D,

but the new reference means the **2.5D family must receive the most serious treatment**.

Do not spend equal effort on obviously unrelated flat/debug variants merely to fill a
quota.

## 3.4 Camera composition

The battlefield/map should be the hero.

At a 1280x720 reference viewport:
- map should occupy roughly 65–80% of the meaningful visual area;
- permanent UI should not reduce the map to a small central panel;
- contextual controls can sit at an edge;
- overlays should appear on top of the world, not replace it.

These percentages are visual hypotheses, not hard engine constraints.

---

# 4. Tile/grid language

## 4.1 Logical grid may remain square

The underlying Battle Simulator grid may remain square and deterministic.

The visual layer may render square logical tiles as:
- diamond/isometric tiles,
- soft-edged terrain patches,
- shallow blocks/plates,
provided selection remains unambiguous.

## 4.2 Grid visibility

The world should NOT look like Excel.

Default state:
- no thick permanent grid lines;
- tile boundaries can be implied by terrain seams, subtle edges or lighting.

When needed:
- selected tile,
- reachable area,
- attackable area,
- path,
can reveal the logical tile structure with translucent overlays.

## 4.3 Tile depth

For 2.5D options, tiles may have:
- a shallow visible side face;
- subtle drop shadow;
- terrain height variation;
- raised hills/rocks.

But avoid:
- huge floating cubes;
- Minecraft-like block world unless explicitly tested as a variant;
- deep cliffs on every tile.

---

# 5. Terrain hierarchy

The most important terrain rule:

> First read the biome/terrain class, then notice decorative detail.

Terrain art must communicate gameplay before decoration.

---

# 6. Plains / grassland

## Desired impression

Open, easy, calm, traversable.

The player should visually understand that this is the easiest terrain to cross.

## Shape language
- broad open ground;
- short grass;
- gentle color variation;
- occasional tiny tufts/flowers;
- low visual obstruction.

## Surface treatment
- soft painted ground texture;
- no repeated obvious stamp pattern;
- subtle noise only;
- slight local hue shifts.

## Density
Decoration should remain sparse enough for:
- units,
- selection rings,
- paths,
- improvements.

## Avoid
- blank green square;
- neon lawn;
- single grass emoji;
- tall grass covering figures.

---

# 7. Farmland / cultivated field

Farmland should visually differ from wild plains.

Possible elements:
- rows of crops;
- worked soil strips;
- small fences;
- hay stacks;
- irrigation hints;
- organized rectangular patches inside the tile.

The key idea:
**human intervention is visible.**

Do not make a farm merely "plains + wheat icon".

---

# 8. Forest

## Desired impression

Dense enough to feel wooded and slower to cross, but still playable.

## Shape language
- multiple tree masses;
- layered canopy;
- varied tree height;
- darker center / lighter edges;
- occasional visible trunks/path gaps.

## Readability
Units standing in forest must remain identifiable.

Use one or more:
- local clearing around unit;
- foreground foliage fade;
- unit render layer above canopy;
- silhouette outline;
- canopy transparency near selection.

## Avoid
- one tree icon per tile;
- identical repeated Christmas trees;
- canopy so large it hides adjacency;
- forest becoming a solid dark square.

---

# 9. Hills

## Desired impression

Raised, uneven, defensible/rougher terrain.

Use:
- sloped ground;
- exposed stone;
- small ledges;
- elevation shadow;
- uneven grass.

Hills must look different from mountains.

Hill = traversable elevated terrain.
Mountain = major geographic mass / future stronger obstacle.

Avoid making every hill into a giant peak.

---

# 10. Mountains

Mountains are primarily a **visual-direction library item** until mechanics are fixed.

Desired:
- strong vertical silhouette;
- layered rock;
- clear ridge logic;
- visual mass greater than hills.

Map-generation note:
the current Epohi generator previously produced oversized accidental hill/mountain
blobs. The visual style must not assume that is desirable geography.

Future generation should favor:
- ridges,
- ranges,
- passes,
- isolated peaks,
rather than arbitrary half-map brown clusters.

---

# 11. Rough / broken ground / rocks

For Battle Simulator's existing Rough terrain, explore imagery such as:
- broken stones;
- uneven earth;
- low rock formations;
- roots/stumps;
- rubble patches.

It should visually explain "harder ground" without looking like a mountain tile.

---

# 12. Water: lake / sea / coast

## Desired impression

Pleasant, living water with clean strategic readability.

Use:
- hand-painted wave rhythm;
- shoreline foam or light edge;
- subtle gradient;
- small highlights;
- shoreline shape cues.

Lake and sea may later diverge visually:
- lake calmer/greener/darker;
- sea broader/bluer/more directional waves.

Avoid:
- flat cyan square;
- hyper-real reflection;
- visually noisy animated water;
- water overpowering nearby land.

---

# 13. Roads / paths

Road/path visuals should be embedded in terrain.

Desired:
- dirt track,
- worn grass,
- stones,
- bridges where appropriate later.

Roads should connect continuously between tiles.

Do not render them as floating UI lines when they represent world infrastructure.

Route-preview UI is a different layer and can use overlays/arrows.

---

# 14. Improvements / work sites

Improvements must feel like **places where something happens**.

This is strongly inspired by what the user liked in the reference.

## 14.1 Lumber / sawmill direction

Should imply:
- felled trees,
- stacked logs,
- cutting/work area,
- small shelter/workbench/saw frame,
- workers or activity props in richer variants.

Do not reduce it to a log icon.

## 14.2 Farm

Should imply:
- cultivated soil,
- crop rows,
- harvest,
- ordered human activity.

## 14.3 Mine

Should imply:
- exposed rock,
- mine entrance,
- timber supports,
- ore pile/cart/track in richer variants.

## 14.4 Trading post

Should imply:
- small stalls,
- crates,
- canopy/cart,
- exchange/activity.

## 14.5 Harbor

Should imply:
- shore structure,
- pier,
- boats/crates/ropes,
- clear land-water relation.

---

# 15. City / settlement presentation

Cities should become physical places, not mere badges.

Possible progression:
- early settlement: tents/huts/fire;
- village: several structures;
- town: denser cluster;
- capital/state center: recognizable central landmark.

The first Lab does not need full city-growth animation.

But variants should demonstrate that:
- cities occupy space;
- buildings visually belong to terrain;
- city scale is meaningful;
- a city can grow later without replacing the art direction.

---

# 16. Unit art — general rules

This is the second-highest priority after terrain.

## 16.1 Units must look alive

Every unit representation should read primarily as:
- person,
- small group of people,
- miniature formation.

Not primarily as:
- text label,
- faction shape,
- circular marker.

## 16.2 Readability before anatomy

Figures can be stylized and simplified.

Important:
- head/body/weapon/tool silhouette;
- pose;
- faction cue;
- class cue.

Not important:
- realistic fingers;
- facial detail at tactical zoom;
- realistic cloth simulation.

## 16.3 Relative size hypothesis

For 2.5D prototype variants:
- one individual figure should occupy roughly 25–40% of a tile's visible width;
- a small 3-figure squad may occupy roughly 45–70%;
- height can exceed tile footprint because this is a 2.5D world.

These are starting hypotheses for the Lab, not final locked values.

## 16.4 Grounding

Units need to feel planted on the world:
- contact shadow;
- small base shadow;
- feet aligned to ground;
- correct draw ordering.

Avoid floating sprites.

---

# 17. Guard unit

Visual semantics:
- durable;
- protective;
- disciplined.

Useful cues:
- shield;
- heavier clothing/armor;
- spear or short weapon;
- wider/stable stance;
- compact formation.

Do NOT communicate Guard merely by the letter G.

---

# 18. Striker unit

Visual semantics:
- offensive;
- mobile/aggressive;
- lighter than Guard.

Useful cues:
- sword/axe;
- forward pose;
- narrower shield or no shield;
- more dynamic silhouette.

Do NOT make Striker indistinguishable from Guard except color.

---

# 19. Archer unit

Visual semantics:
- ranged;
- lighter;
- vulnerable at close distance.

Useful cues:
- visible bow;
- quiver;
- stance distinct from melee;
- slightly more open formation.

Bow silhouette should be visible at normal Lab zoom.

---

# 20. Commander

Commander must be recognizable without becoming a giant hero.

Possible cues:
- small banner;
- plume;
- cloak;
- slightly different headgear;
- small standard bearer;
- subtle gold trim;
- commander marker above group.

Avoid:
- commander twice the size of soldiers;
- giant portrait covering tile;
- huge glowing aura in default state.

---

# 21. Squad representation variants

The Visual Lab should explore several approaches within the same art family:

1. **single representative figure**
2. **three-person miniature formation**
3. **commander + two fighters**
4. **banner + compact troop cluster**
5. **small formation with role-specific silhouettes**

The user should be able to compare these directly.

---

# 22. Blue / Red faction readability

Faction identity must not depend only on hue.

Use at least two channels:
- cloth/banner color;
- banner shape;
- shield pattern;
- base trim;
- outline;
- small faction pennant.

At a glance, Blue and Red must remain distinct even where terrain colors are similar.

---

# 23. Selection state

Selection should feel integrated with the world.

Preferred tools:
- soft ground ring;
- subtle glow;
- raised brightness;
- small banner highlight;
- selected tile rim;
- shadow/outline accent.

Avoid:
- enormous neon rectangle;
- debug bounding box;
- blinking thick border.

---

# 24. Reachable movement overlay

Must reveal the logical gameplay area while preserving terrain.

Preferred:
- translucent tint;
- soft edge;
- gentle pulsing optional later;
- terrain remains visible underneath.

Do not repaint reachable terrain as solid green blocks.

---

# 25. Attack target overlay

Should read immediately as danger/target.

Possible:
- red-orange rim;
- target reticle;
- small crossed-weapons indicator;
- enemy outline.

Do not obscure unit art.

---

# 26. Route / path preview

Preferred visual:
- small arrows,
- footprints,
- dots,
- soft painted route,
- directional chevrons.

It should look like an instruction overlay, not a permanent road.

---

# 27. Damage / health display

Default map view should remain clean.

Prefer:
- compact health pip/bar only when selected, damaged, hovered or relevant;
- member count near squad;
- detailed HP in contextual panel.

Avoid permanently showing large numeric blocks over every unit.

---

# 28. Environmental storytelling

Richer variants may add:
- chopped tree stumps near lumber site;
- carts near mine;
- smoke from workshop;
- tiny campfire;
- stacked crates;
- worn paths;
- flowers;
- reeds;
- birds;
- flags.

These are secondary.

Do not add them before terrain/unit readability works.

---

# 29. Color and palette

## Overall palette

Target:
- natural,
- warm,
- slightly muted,
- colorful enough for immediate terrain distinction.

Avoid:
- monochrome brown fantasy;
- oversaturated candy palette;
- cold blue-gray everywhere.

## Value hierarchy

Suggested:
- ground = mid values;
- units = slightly stronger local contrast;
- UI overlays = clear but translucent;
- interactable state = strongest controlled accent.

## Terrain separation

Grass, forest, hill, water and rough ground must remain distinguishable even if hue
perception is reduced.

Use:
- value,
- texture,
- silhouette,
not color alone.

---

# 30. Lighting

Target:
- soft directional daylight;
- readable shadows;
- enough occlusion to imply depth.

Avoid:
- dramatic dark cinematic lighting;
- strong bloom;
- deep black shadows hiding units;
- physically realistic lighting complexity in first Lab.

A mild top-left or upper-side light is a good reversible starting hypothesis.

---

# 31. Shadows

Use shadows to ground the miniature world:
- trees,
- units,
- buildings,
- raised rocks.

Shadows should be:
- soft,
- compact,
- consistent.

Avoid massive dark projected shadows that hide grid state.

---

# 32. Animation philosophy

The first visual stand does not require full animation.

Later desired feel:
- small idle motion;
- flag movement;
- gentle foliage;
- short unit step;
- restrained attack feedback.

Animation must support clarity, not become spectacle.

---

# 33. UI visual language

The world and interface should feel related.

Preferred UI family:
- dark natural green,
- warm parchment/cream,
- wood/leather/brass/stone accents,
- restrained fantasy ornament,
- rounded but not toy-like panels.

The newer local Epohi rebuild already provides a useful structural reference:
- map first,
- compact top information,
- contextual side panel,
- major turn/action control at bottom.

The external visual reference adds:
- richer crafted materials;
- stronger miniature-world atmosphere;
- less "web app" feeling.

---

# 34. UI density

The UI must not drown the map.

Contextual data should be progressive:
- basic info visible;
- more detail after selection;
- deep stats on request.

Avoid:
- giant permanent debug command list;
- verbose event feed dominating right side;
- every statistic always visible.

---

# 35. Typography

Typography should be:
- readable;
- slightly characterful;
- not overly decorative.

Use decorative serif/display treatment only for:
- major headings,
- faction/city labels,
- special cards.

Use a highly readable font for:
- numbers,
- combat information,
- buttons,
- descriptions.

Do not make all UI medieval-script styled.

---

# 36. Interaction targets

Because future Epohi use includes mobile:
- people/tiles must remain tappable;
- visuals cannot require pixel-perfect clicks;
- selection highlight should confirm touch clearly;
- overlapping figures should not make tile targeting ambiguous.

The Battle Simulator Lab may be desktop-first, but avoid designing an art direction
that cannot later scale to mobile.

---

# 37. The Visual Lab must compare coherent PACKS, not isolated random assets

An art direction is not just one pretty tree.

Each serious option should include a coherent sample pack:
- ground/plains;
- forest;
- hill/rock;
- water;
- one improvement;
- Guard;
- Striker;
- Archer;
- commander cue;
- Blue/Red treatment;
- selected/reachable/target overlays.

This lets the user judge whether a style works as a system.

---

# 38. Stable ID scheme

Use IDs such as:

## Packs
- PACK-25D-A
- PACK-25D-B
- PACK-25D-C

## Terrain
- TERRAIN-PLAIN-25D-A01
- TERRAIN-FOREST-25D-A01
- TERRAIN-HILL-25D-A01

## Units
- UNIT-GUARD-25D-A01
- UNIT-STRIKER-25D-A01
- UNIT-ARCHER-25D-A01

## Improvements
- IMPROVEMENT-LUMBER-25D-A01

Do not use filenames like:
- final2,
- test_new,
- better_one,
- temp3.

The user must be able to say exactly:
"keep A03, archive B02".

---

# 39. Variant strategy

The older goal of up to 10 variants per role/mode remains useful, but do NOT create
90 weak variants.

Use stages:

### Stage A — Direction discovery
Create 4–6 genuinely different coherent packs.

### Stage B — Family expansion
For the 1–2 promising packs, expand:
- terrain variants;
- unit variants;
- formations;
- detail density.

### Stage C — Final shortlist
Reach up to ~10 variants where comparison is actually valuable.

Quality and meaningful difference are more important than count.

---

# 40. Required first direction families

Within the new preferred style, explore at least these families:

## A. Clean painted isometric
- clearest shapes;
- moderate detail;
- strategy readability first.

## B. Cozy detailed miniature
- richer props;
- more environmental life;
- closest to the emotional appeal of the reference.

## C. Civilization-scale painted
- slightly simpler figures;
- slightly larger terrain language;
- better for zoomed-out large maps.

## D. Chunkier storybook 2.5D
- stronger shapes;
- simplified texture;
- excellent small-screen readability.

Do not include unrelated pixel-art / realistic military / abstract-board options in the
main shortlist unless the user explicitly asks.

---

# 41. 2D / 2.5D / 3D experimentation rule

The user previously wanted to compare 2D, 2.5D and 3D.

The new reference shifts priority:

1. **2.5D is primary**
2. 2D remains useful as a simplified alternative
3. true 3D is exploratory only

If true 3D requires disproportionate engineering work, use a lightweight faux-3D
prototype instead.

Do not spend days creating a 3D pipeline before the user approves the overall look.

---

# 42. Godot implementation implications

Preferred early implementation techniques:
- Node2D / Control composition;
- custom draw for overlays;
- sprite-like procedural placeholders;
- Polygon2D where useful;
- simple generated textures;
- simple MultiMesh/3D sample only for exploratory 3D variant if needed;
- data-driven variant Resources.

Do not tightly couple art choice to combat domain.

Visual variants must be replaceable without changing:
- battle legality,
- AI,
- RNG,
- replay,
- balance.

---

# 43. Asset strategy for the prototype

For the first stand, use:
- original procedural shapes;
- original generated sprite-like drawings;
- simple meshes;
- original textures created for the project;
- properly licensed assets only if later deliberately introduced.

Do NOT:
- scrape game assets;
- trace exact characters/buildings;
- reproduce recognizable proprietary UI frames;
- import screenshots as final game art.

---

# 44. Acceptance test for each visual pack

A pack is useful only if all are true:

1. From normal zoom, user can identify terrain type quickly.
2. Guard / Striker / Archer differ without reading letters.
3. Blue / Red differ without relying only on color.
4. Selected squad is obvious.
5. Reachable and target overlays are obvious.
6. Terrain remains visible under overlays.
7. Unit remains visible in forest/rough terrain.
8. Improvement reads as a world place, not an icon sticker.
9. The map feels like a miniature fantasy world.
10. The screen does not resemble a debug/test harness.

---

# 45. Anti-target checklist

If a result looks primarily like any of these, it is wrong:

- spreadsheet
- debug tactical editor
- colored tile matrix
- boardgame counters
- military command software
- generic web dashboard
- abstract chess board
- photoreal war game
- neon mobile RPG
- card battler
- pixel-art retro game

---

# 46. What to preserve from current Epohi visual language

The newer local Epohi rebuild remains useful for:

- readable square-grid strategy logic;
- map-first composition;
- immediately distinct terrain families;
- compact little people;
- contextual side panel;
- warm dark-green / parchment UI family;
- clear strategic density.

The new isometric reference should **elevate** those strengths, not erase them.

---

# 47. What to improve beyond current Epohi

Push further toward:

- real terrain volume;
- more coherent environments;
- humans as miniature characters rather than mostly icon/sprite symbols;
- improvements as physical work sites;
- stronger depth;
- richer but controlled detail;
- more handcrafted atmosphere.

---

# 48. Final decision rule for Orca

When choosing between two implementation interpretations, prefer the one that better
satisfies:

**readable strategy map + miniature living fantasy world + human figures + coherent
terrain depth**

over:

**technical simplicity + abstract markers + flat debug readability**

while still preserving click/touch clarity.

If a choice is visually uncertain, expose both as variants instead of silently deciding
for the user.

---

# 49. Human-review rule

The user, not the agent, chooses the final style.

Orca must:
- generate options;
- label them;
- make them easy to compare;
- preserve shortlisted options;
- archive rejected ones.

Orca must NOT:
- declare one option final;
- delete alternatives because it prefers one;
- merge the visual experiment into the final battle presentation without approval.

---

# 50. Summary for future agents

The user wants the visual direction to move toward:

**stylized isometric 2.5D fantasy strategy art with hand-painted/sprite-like terrain,
small living people, meaningful work sites/buildings, warm natural colors, clear
silhouettes, soft depth, and a miniature-diorama feeling.**

The game must remain readable as strategy.

The desired reaction is:
> "I want to look at and explore this little world."

Not:
> "I understand the mechanics, but it looks like a prototype."
