# NEXT TASK — Godot Visual Reference Lab: Stylized Isometric Fantasy
Date: 2026-10-03

Repository: Mikayilzade/battle-simulator
Branch: main

## Read before touching files

MANDATORY:
- docs/VISUAL_RULEBOOK_STYLIZED_ISOMETRIC_FANTASY_2026-10-03.md
- docs/EPHOHI_VISUAL_REFERENCE_2026-10-03.md
- docs/VISUAL_LAB_IDEAS_2026-10-02.md
- docs/IMPLEMENTATION_STATUS.md
- docs/BATTLE_SIMULATOR_DESIGN.md

The new visual rulebook has highest priority for art-direction decisions.
Existing combat/domain architecture remains authoritative for mechanics.

---

# Mission

Create a **separate Godot visual comparison stand** for Battle Simulator that demonstrates
the new preferred visual direction.

This is NOT a battle-system rewrite.
This is NOT final game art.
This is NOT permission to redesign mechanics.

The purpose is to give the user concrete visual options to inspect and choose from.

The stand must answer:

1. What should the battlefield itself look like?
2. What should plains / forests / hills / rocks / water / farmland look like?
3. What should Guard / Striker / Archer look like?
4. Should squads be single figures, 3-person groups, banner-led groups, etc.?
5. What level of detail feels right?
6. Which 2.5D family should become the basis for further work?

---

# Critical direction

The current preferred family is:

**stylized hand-painted / sprite-like isometric 2.5D fantasy miniature world**

Think in terms of:
- a small living world;
- real-looking terrain shapes;
- tiny human figures;
- visible work sites;
- cozy fantasy atmosphere;
- high strategic readability.

Do NOT return to:
- debug circles/diamonds;
- letter-coded unit tokens;
- spreadsheet grid;
- giant permanent command panel;
- flat colored squares as the primary visual language.

---

# Scope boundary

Do not change:
- combat rules;
- battle balance;
- deterministic scheduler;
- RNG;
- replay;
- baseline AI;
- headless simulation;
- domain state schemas unless a visual-only ID/catalog addition is strictly necessary.

Do not implement:
- campaign;
- Epohi integration;
- networking;
- production/training simulator;
- audio;
- final Windows export;
- complex animation system.

The stand may live beside existing UI and may be launched independently.

---

# Required Lab architecture

Prefer a dedicated structure such as:

ui/visual_lab/
    VisualLab.tscn
    visual_lab.gd
    components/
    previews/
    catalogs/

data/visual/
    VisualPackDef resources/scripts
    TerrainVisualDef
    UnitVisualDef
    OverlayVisualDef

Exact filenames may vary if a cleaner Godot structure exists.

Important:
- variant data must be separable from browsing UI;
- stable IDs must be data, not button labels only;
- adding another variant later should not require rewriting the whole screen.

---

# Required navigation

The stand should contain at least these sections/tabs:

1. **PACKS**
2. **TERRAIN**
3. **UNITS**
4. **COMBINED PREVIEW**
5. **SHORTLIST / ARCHIVE**

The user should be able to move quickly between them.

---

# PACKS section

Create **at least 4 coherent 2.5D visual families** based on the rulebook.

Mandatory families:

## PACK-25D-A — Clean Painted Isometric
Goal:
- strongest readability;
- moderate detail;
- soft painted ground;
- clear unit silhouettes;
- restrained props.

## PACK-25D-B — Cozy Detailed Miniature
Goal:
- richer environmental storytelling;
- more logs/fences/plants/rocks;
- miniature-diorama feel;
- closest to the emotional appeal of the reference;
- still readable.

## PACK-25D-C — Civilization-Scale Painted
Goal:
- more zoomed-out strategy readability;
- larger terrain shapes;
- simplified people;
- lower decoration density;
- suitable direction for a future larger Epohi map.

## PACK-25D-D — Chunky Storybook 2.5D
Goal:
- stronger simplified forms;
- excellent small-screen readability;
- softer toy/storybook proportions without becoming plastic;
- more stylized silhouettes.

These must differ meaningfully in:
- terrain shape;
- figure proportions;
- detail density;
- edge treatment;
- shadow treatment;
not just palette.

Optional:
- one 2D comparison pack;
- one faux-3D comparison pack.

Do not let optional packs delay the four main 2.5D packs.

---

# TERRAIN section

For each main pack, create at minimum a representative version of:

- plains / grassland
- farmland
- forest
- hill
- rough/broken ground
- rocks/blocker
- lake/water
- road/path

Also include a **mountain exploration sample** and a **sea exploration sample**, even if
they are not used by current Battle Simulator rules.

Terrain must visually obey the rulebook.

Important:
- forest must be multi-tree/wooded, not one icon;
- hill must show elevation;
- rough must not look identical to hill;
- water must have shoreline/wave language;
- farm must look cultivated;
- road must visually connect.

---

# UNIT section

Core roles:
- Guard
- Striker
- Archer

For each of the four 2.5D packs, provide at least **3 unit representation approaches**
per role:

1. single representative figure;
2. compact 3-person formation;
3. commander/banner-led formation.

This gives at least 9 useful unit comparisons per pack across roles, without filling the
screen with meaningless palette swaps.

If implementation time remains, expand toward the older long-term target of up to 10
variants per role.

Do not generate filler to hit a number.

---

# Guard visual constraints

Must communicate:
- defense;
- stability;
- heavier protection.

Use some combination:
- shield;
- spear;
- heavier armor/clothing;
- compact stance.

---

# Striker visual constraints

Must communicate:
- offense;
- forward motion;
- lighter/more aggressive role.

Use:
- sword/axe;
- attacking silhouette;
- lighter protection;
- dynamic stance.

---

# Archer visual constraints

Must communicate:
- ranged role immediately.

Use:
- visible bow;
- quiver;
- ranged posture.

A user should distinguish Archer without a label.

---

# Commander treatment

Create at least 3 commander cues that can be compared:
- small banner;
- plume/cloak;
- subtle gold/trim marker.

Do not make commander a huge hero character.

---

# Blue / Red treatment

Each preview must show both sides together.

Sides must differ by more than color.

Use at least one additional channel:
- banner shape;
- shield mark;
- trim pattern;
- pennant shape.

Do not make the user rely only on blue/red hue.

---

# COMBINED PREVIEW

This is the most important screen.

Create one representative small diorama/battlefield containing:

- plains
- forest
- hill
- rough ground
- blocker/rocks
- water edge or lake
- farm
- road/path
- one small work site/improvement
- Blue Guard
- Blue Archer
- Red Guard
- Red Striker
- commander cue

Allow selected visual PACK to swap the whole coherent presentation.

Also permit, if reasonably simple:
- terrain variant override;
- unit representation override.

---

# Required preview states

Combined Preview must include controls to display:

1. normal state;
2. selected squad;
3. reachable tiles;
4. attackable target;
5. route/path preview;
6. damaged unit;
7. dense/forest overlap case.

The goal is to judge whether the art still supports gameplay overlays.

---

# Overlay requirements

## Selected
Use a world-integrated ring/rim/glow.

## Reachable
Translucent overlay; terrain remains visible.

## Target
Clear red/orange target language without hiding figure.

## Route
Footprints / dots / arrows / chevrons.

Do not use thick debug rectangles unless shown only as an explicit comparison variant.

---

# Improvement / work-site sample

At minimum, create one lumber/sawmill-like sample and one farm sample.

The lumber sample should suggest:
- felled logs;
- wood stacks;
- work structure;
- human activity.

The farm sample should suggest:
- worked soil/crops;
- ordered cultivation.

These must look like places, not sticker icons.

---

# Detail-density control

For at least one pack, expose 3 detail-density levels:

- LOW
- MEDIUM
- HIGH

This is important because the user's reference is rich, but future Epohi may need many
tiles visible at once.

The user should be able to determine how much environmental detail remains readable.

---

# Scale comparison

Provide at least 3 unit-scale settings for one pack:

- SMALL
- MEDIUM
- LARGE

The goal is to answer:
how large can the little people be before they obscure terrain/grid information?

Do not silently pick one final ratio.

---

# Optional camera-angle comparison

If inexpensive, expose 3 camera/presentation angles:

- more top-down;
- balanced 2.5D;
- stronger isometric angle.

Do not build a complex free camera.
These may be fixed presets.

---

# Shortlist / archive behavior

Every important variant/pack needs a stable ID.

Support status:
- neutral
- favorite
- archived
- selected

Do not delete archived choices.

A user should be able to report:
- "PACK-25D-B is best"
- "UNIT-ARCHER-25D-B03 is good"
- "archive PACK-25D-D"
without ambiguity.

Persist locally if simple.
If persistence would distract from the visual task, keep session state but structure it
so persistence can be added later.

---

# No copied commercial assets

All prototype visuals must be:
- original procedural Godot drawing;
- original generated simple textures/sprites;
- simple original meshes;
- or explicitly properly licensed assets if already available in repo.

Do NOT:
- download the reference game's sprites;
- trace its characters;
- recreate exact UI frames;
- copy exact buildings;
- use the screenshot as a texture;
- reproduce recognizable proprietary iconography.

The goal is style-direction testing, not imitation.

---

# Background work behavior

If the user is not actively waiting for a visible window:
- do not steal focus repeatedly;
- do the implementation and headless checks in background.

For this task, visual output ultimately needs human review.

At the end:
- do NOT decide the winner;
- do NOT replace the current main battle UI with a selected pack;
- leave the Lab ready to open later.

If a visual screenshot can be produced without disturbing the user, that is optional,
not required.

---

# Godot implementation preference

Use Godot 4 + GDScript.

Prefer:
- reusable Node2D components;
- custom draw for tile/overlay prototypes;
- small procedural/generated sprite-like assets;
- data-driven Resources for variants;
- clean separation between catalog and renderer.

Do not put combat domain logic into visual nodes.

---

# Performance guardrail

This is a comparison stand, not final optimization.

Still avoid obviously pathological design:
- thousands of individual heavy Controls per tile;
- per-frame rebuilding of static terrain;
- complex shaders for tiny gains.

The stand should remain responsive at 1280x720.

---

# Verification

Run:

1. Godot headless import.
2. Existing validation tests.
3. Existing command tests.
4. Existing replay/scheduler/RNG tests.
5. Existing AI tests.
6. VisualLab scene load smoke test.
7. Verify every declared pack/variant ID resolves.
8. Verify no duplicate stable IDs.
9. Verify Combined Preview can instantiate each main pack.

Do not rerun 10k simulations unless combat/domain files change.

---

# Documentation checkpoint

Update docs/IMPLEMENTATION_STATUS.md with:

- Visual Lab architecture;
- pack IDs created;
- terrain families present;
- unit variants present;
- overlay states present;
- commands/tests actually run;
- visual limitations;
- exact things requiring user review.

---

# Git

Before editing:
- git status;
- confirm main;
- confirm no unrelated local changes.

After:
- inspect diff;
- git diff --check;
- run verification;
- commit only this visual-lab package;
- push main.

Suggested commit:

`feat: add isometric fantasy visual reference lab`

---

# Stop condition

Stop when:
- at least four coherent 2.5D packs exist;
- combined preview works;
- terrain and units are meaningfully distinguishable;
- shortlist/archive IDs work;
- the stand is ready for human visual comparison.

Do NOT continue into:
- choosing the final style;
- replacing battle UI;
- reworking combat;
- exporting final build.

The user's next action should be visual review and selection.
