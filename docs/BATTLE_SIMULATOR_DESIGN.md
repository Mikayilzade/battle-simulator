# Battle Simulator — design package for the first MVP

**Status:** design proposal, 2026-09-28. No Battle Simulator mechanic, balance
number, engine choice or future Epohi integration in this document is approved
merely by committing it. The only output of this stage is this reviewable design.
The first implementation, repository creation and any Epohi menu entry are
separate later actions.

**Decision labels:** **Known** records the user's stated intent or an accepted
Epohi architecture constraint. **Hypothesis** is the proposed starting choice,
replaceable after playtesting. **Decision needed** requires the user's answer
before implementation. Source: [Design Inbox](DESIGN_INBOX_2026-09-23.md),
especially its user notes and open questions, and [accepted architecture
decisions](ARCHITECTURE_AUTONOMY_DECISIONS_2026-09-26.md), sections 6–8 and 13.
The inbox itself explicitly does not approve implementation.

## 1. What is known / accepted

- **Known for this stage:** design only, no game code, repository, branch or new
  PR. The document lives in Epohi PR #103. Battle Simulator is a separate
  mini-game hypothesis. Adding a future «Симулятор боя» item to Epohi is
  conditional on the separate game succeeding and on a later decision.
- **User intent recorded in the inbox, not approved rules:** select a standard
  map, assemble both sides, optionally autofill, play one turn-based battle for
  immediate fun. The suggested hierarchy is individual → squad → battalion →
  army; a squad may have a more experienced commander and at least two same-type
  fighters. Front/rear protection and commander growth are ideas, not formulas.
- The wish for a playable experience in roughly a day is a **speed signal**,
  not a fixed deadline or authorization to cut core playability. There is no
  approved roster cap, damage formula, map set, art direction or action unit.
- **Accepted architectural constraints from Epohi:** rules and state do not
  depend on UI or animations; tunable balance is data; commands change canonical
  state and return results while presentation consumes events; deterministic
  randomness is available for tests. These principles transfer; Epohi's combat
  numbers and its current movement costs do not.

## 2. Questions that actually block first implementation

Only two choices would make an early implementation expensive to reverse:

1. **What receives an activation and what spends an action?** The inbox gives
   both «3 people → 3 actions» and «5 squads → 5 actions». These can mean
   different levels of control. It changes the core turn loop, UI and AI.
2. **Is the first experiment primarily a quick web game or a Godot learning
   experiment?** The stack changes scene/UI implementation and the cost of
   moving successful mechanics back into browser-based Epohi.

The MVP below is a concrete **hypothesis**, conditional on the two answers.
Opponent AI, map count, draft sizes, stats, formulas, art treatment and
animation speed have reversible defaults; none needs a blocking question now.
Commander progression, army-scale rules, production and integration are outside
the first battle.

## 3. Blocking choices: options, tradeoffs and starting recommendation

### A. Activation and action grain — **DECISION NEEDED**

| Option | Advantages | Costs | Cost to change later |
| --- | --- | --- | --- |
| Individual: activate each fighter; one move or attack per fighter | Direct tactical control; «3 fighters → 3 actions» is literal | More clicks and longer battles; battalions may need aggregation or automation | High if squad-level combat later becomes the main mode |
| Squad: activate one squad; resolve its members as a single attack/order | Fast, clear, easiest to scale to «5 squads → 5 actions» | Individual wounds and commanders may feel like passive numbers | High if later individual choices become central |
| **Hybrid (recommended): activate each squad once, with an action pool equal to its living members** | Three fighters supply three actions inside one squad activation; battalion can schedule five squad activations; individual HP still matters | Two nested concepts must be explained; a move is a collective squad order paid from the pool | Medium: explicit activation/action interfaces isolate the choice, but UI and AI still change |

**Proposed interpretation:** two squads per side; alternate squad activations.
When a squad activates, it receives one action point per living member. A move,
one member's attack, guard or front-line reorder costs one point. A member
attacks at most once in that activation; one squad move moves its single map
token and is allowed at most once. Thus three intact members can make three
attacks if they do not move. «Five squads → five activations» is **not** the
same as five total attacks; the user should accept or reject this distinction.

### B. First implementation stack — **DECISION NEEDED**

| Option | Advantages for this MVP | Costs for this MVP | Cost to change later |
| --- | --- | --- | --- |
| **Web/JavaScript (recommended for the fastest Epohi-relevant experiment)** | Existing JS and Playwright skills; browser playtest by link; pure combat package can be adapted into Epohi with limited translation | Need to build a compact grid and UI; does not teach Godot | Switching the presentation to Godot is high; rules can be ported at medium cost if kept engine-free |
| Godot/GDScript | Scene tools, 2D layout and animation iteration; genuinely tests whether Godot improves this kind of game | New engine workflow and GDScript combat implementation; transfer to Epohi requires translating rules and data adapters | Switching to web/Epohi is high for UI and medium to high for rules, especially if rules use Nodes |

**Recommendation:** web/JS for a short, testable tactics loop and reuse of the
result in Epohi. If the main aim is to **evaluate Godot itself**, choose Godot
with GDScript and keep the same rules/data/UI boundaries. Godot supports web
exports, but the documented web path adds WebAssembly/WebGL requirements; its
headless CLI can run scripts for batch simulations. Godot 4 C# projects cannot
currently be exported to web, so C# is a poor default for a browser-playable
Godot prototype. These are platform facts from the [Godot web export guide]
(https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html),
[command-line guide](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)
and [C# guide](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/index.html),
not a claim that Godot is generally slower to develop games in.

## 4. Proposed minimum fun MVP — **HYPOTHESIS, not approved balance**

### One-battle loop

Start → choose one of two maps → edit two forces or autofill → inspect matchup
and deploy → battle with alternating squad activations → immediate result with
casualties, decisive turns and rematch. Target a 5–10-minute first match and
make «Autofill both → Start» possible in two intentional interactions. Those
times are playtest targets, not delivery promises or hard acceptance gates.

| Element | Exact initial proposal | Why this is the minimum useful experiment |
| --- | --- | --- |
| Maps | Two fixed, mirrored 9×7 square grids: **Open Field** (clear center, two rough cover tiles) and **Broken Pass** (two blockers, two rough flanks, at least two routes). No procedural generation. | Tests direct combat and cover/flanking without random map balance. |
| Sides | Blue is human-controlled; Red uses a deterministic simple AI. Both compositions are editable; AI uses the same legal commands and information as the player. A later hotseat/autoplay switch changes controller policy, not combat rules. | A solo battle is immediately playable; enemy decisions are observable. |
| Force size | Exactly two squads per side, three individuals per squad: one commander and two same-type fighters. Six people per side. Each squad has one map token and internal front/rear slots. | Enough composition and casualty choices without army-management UI. |
| Unit types | **Guard** (durable melee), **Striker** (mobile melee), **Archer** (range 3). A squad is homogeneous; its commander shares its type. Duplicates are allowed. | Three distinct jobs expose positioning and balance quickly. |
| Turn | One round contains alternating activations: Blue squad, Red squad, Blue squad, Red squad. Every living squad activates once. First side alternates by round. Unspent action points expire. | Opponent can answer before the whole force acts; no turn carryover. |
| Actions | Per activation, action points equal living members. Move token once, attack with an eligible member once, guard or reorder front: each costs one point. A member attacks at most once; pass ends activation. Guard gives the squad +1 armor until its next activation and does not stack. AI obeys the same budget. | Casualties reduce tempo as well as HP; choices have a visible opportunity cost. |
| Movement | Orthogonal steps; no shared occupancy. One move command can traverse up to a squad-type movement budget: Guard 2, Striker 3, Archer 2. Plain costs 1, rough costs 2, blockers impassable; shortest legal route is shown before commit. No saved movement bank or diagonal shortcut. | Readable route decisions without importing Epohi's disputed movement costs. All numbers are data. |
| Attack | Melee targets an adjacent enemy squad; Archer targets up to Manhattan distance 3 with clear line of sight. Choose target squad; ranged may deliberately select a rear member. Attack is deterministic initially; no hit/miss, crit or counterattack. | Damage can be understood after one battle and tuned without random noise. |
| Damage / HP | Guard: HP 12, armor 3, power 4. Striker: HP 9, armor 1, power 6. Archer: HP 8, armor 0, power 5. Commander has +2 maximum HP and +1 attack power. Damage = `max(1, attacker power − target armor − cover − guard)`; cover and guard each contribute 1. Target loses HP; at 0 it leaves the formation. | Small integers make results legible. Armor reduces damage, never makes a unit invulnerable. |
| Front/rear | Each squad has one front and up to two rear members. Melee hits front; if front dies, next healthy member takes the slot before the next strike. Ranged hits front by default or an explicitly selected rear member with −2 attack power. At squad activation, default front is member with highest current `HP + armor`; ties use stable roster order. Reorder spends one action and holds until that squad's next activation. | Protecting a commander or wounded fighter creates decisions without a second grid. «Front» is a formation slot, not a separate map row. |
| Commander | An actual member, eligible to attack, initially stronger as above. Its death removes its actions and bonus. The result records attacks survived, assists, kills and battles survived, but no persistent XP or selectable skill tree in MVP. | Commander matters now; later training can consume recorded facts without inventing its progression formula today. |
| Victory | Eliminate all enemy members. At 20 rounds, compare living-member count, then total remaining HP; equal values are a draw. The game always ends. No reinforcements, morale, capture or campaign consequences. | Supports short experiments and avoids permanent stalemate. |
| Autofill | One button per side and «both»: choose Guard + Archer by default; a visible alternate preset Striker + Archer. Same preset and commander rule on both sides; no hidden random advantage. | The battle can begin immediately and be compared fairly. |
| Restart/rematch | **Restart** restores exact map, rosters, seed and side order; **Rematch** preserves map/rosters and swaps spawn sides. Both return directly to battle after a confirmation if a battle is still active. **Edit forces** returns to setup. | Rapid comparisons without repeating the setup flow. |

**AI starting policy:** attack an enemy squad if legal, prefer a lethal strike,
otherwise the nearest vulnerable squad; move toward an attack route, avoiding
blocked cells; guard if no useful attack/move remains. All ties use a seeded
stable ordering. AI is intentionally a baseline opponent, not a separate set of
combat privileges. Playtests should check both mirror match fairness and whether
players understand why an attack did its damage. Tune values after observation,
without treating the table above as established Epohi balance.

## 5. UI flow for the separate mini-game

1. **Launch:** a single «Play battle» screen with «Autofill both and start» and
   «Customize». The app identifies itself as a separate Battle Simulator. No
   Epohi main-menu entry is specified or implemented.
2. **Map selection:** two illustrated top-down map cards show dimensions,
   obstacles, rough terrain and spawn zones; selection updates a small preview.
3. **Force setup:** Blue and Red panels each show two squad slots. Pick type,
   see three members including commander, HP/armor/power and the predicted front.
   Show six-person cap. Autofill one/both and reset are explicit; start is
   disabled only for an incomplete force. No training, currency or unlocks.
4. **Deployment:** fixed mirrored spawn columns; show both rosters and the
   first-activation rule. One «Start» begins immediately; custom placement is
   deferred. The setup remains one step away if the player wants to edit.
5. **Battle:** center grid with tokens and readable HP markers; side panel has
   round, active squad, remaining actions, its front/rear members and an event
   feed. Selecting a squad highlights reachable cells and legal targets. Click
   a cell or target, inspect predicted damage, then confirm action; keyboard
   controls and a «Pass» action are visible. Red AI actions animate briefly and
   explain their result in the same feed. Animations can be skipped instantly;
   state resolution never waits on them.
6. **Result:** winner/draw, rounds, remaining members and HP, casualties and
   commander facts; buttons for Restart, Rematch and Edit forces. Keep the last
   setup in memory for quick repeat. No save system is needed for one battle.

Visual hypothesis: clear 2D tokens and restrained effects; use color **and**
shape/text to distinguish sides and roles. Art, audio and motion style need a
separate review before a polished visual pass. The tactical grid and semantic
event feed should remain playable with all animations disabled.

## 6. Stack comparison for this MVP

| Criterion | Current web/JS approach | Godot with GDScript |
| --- | --- | --- |
| First playable browser build | Uses Epohi's familiar JS and Playwright workflow; no engine setup. Reuse domain patterns, not its UI monolith. | Scene editor is strong for 2D presentation, but setup, web export and a new language add first-prototype work. |
| Tuning and batch balance | Plain data objects, Node process for thousands of fights, browser only for UI smoke. | Data resources/dictionaries and headless script runner can do this if combat stays independent of scene nodes. |
| Graphics iteration | Canvas/SVG or DOM grid can reach readable MVP fast; bespoke polish needs more UI work. | Built-in 2D scene/animation workflow is attractive once visual feel is the experiment. |
| Port successful mechanics to Epohi | Extracting a pure JS rules package or adapting its algorithms is moderate work; UI is separate either way. | Rules must be translated to JS or bridged through a web build; Godot scenes/UI cannot be pasted into Epohi. |

**Recommendation:** a separate, small web/JS game with no import dependency on
Epohi. Borrow lessons from `src/combat-rules.js` (named combat profiles and
explicit injected random value) and `src/player-combat.js` (state action returns
result), not their current balance or `window` globals. Godot becomes the better
choice if testing Godot production/feel is itself the primary aim. Neither
choice authorizes migration of main Epohi.

## 7. Architecture ready for tuning, scale and headless testing

**Dependency direction:** `balance/map/roster data → combat rules/state
transition → result/events → adapters (AI, UI, animation, sound, telemetry)`.
Adapters never determine whether an attack hit, damage amount or victory.

| Component | Inputs / output | Boundary |
| --- | --- | --- |
| Setup validator | Map ID, two rosters, optional seed → valid `BattleSetup` or errors | Checks cap, homogeneity, commander, unique IDs and spawn legality before battle. |
| Canonical battle state | Round, active side/squad, map, squads and members, HP/formation, spent actions, RNG state, outcome | One source of truth; UI selection, hover and animation frames stay outside it. |
| Pure rules | `state + command + immutable balance + RNG` → next state/result/events | No DOM, Godot Nodes, timers, storage, global randomness or animation callbacks. |
| Command/turn driver | `legalCommands`, `applyCommand`, `advanceActivation`, `finishBattle` | Validates legality; rejects invalid commands without partial mutation. |
| AI policy | Snapshot/legal commands → command | Uses the same rules and information as the player; can be replaced independently. |
| Presentation adapters | Snapshot/result/events → grid, panels, animation, sound | Events are for explanation and playback, not for reconstructing combat truth each turn. |
| Balance catalog | Versioned unit, terrain, movement, armor, damage and AI weights; optional `default/min/max/step` metadata | Freeze shipped defaults; sliders write a temporary overlay/preset, never mutate canonical defaults. |
| Batch runner | Setup + seed range + policies → results/statistics | No UI; thousands of battles in a process for balance and invariant checks. |

Suggested API shape (language-neutral): `createBattle(setup, balance, seed)`,
`legalCommands(state)`, `applyCommand(state, command, balance) ->
{state, events, outcome}`, `chooseAiCommand(state, legal, policy)`, and
`simulateBatch(setups, seeds, policies)`. The RNG seed and balance version are
included in a battle record for exact reproduction. The record is a compact
snapshot plus command log for diagnostics; normal turns read current state.

**Scaling path:** represent a person as a `Combatant` with stable ID and stats;
a `Formation` owns ordered child IDs and a front slot; a `Side` owns formations.
The first rules schedule squad activations and resolve member damage. Later a
battalion can own squad IDs and schedule them without inventing a second damage
formula; an army can own battalion IDs and a general modifier. Higher layers
must declare their action budget explicitly rather than multiplying actions
silently. Only build the individual/squad schema and scheduler now; battalion
and army rules await playtest/design decisions. Rendering reads the same state
through a view model, so token art can be replaced without changing combat.

**Test plan for implementation:** table tests for legality, movement cost,
cover/front targeting, damage, casualties, action counts and win/draw; replay
the same seed/commands to the same result; reject invalid commands without
state changes; run at least 10,000 seeded headless mirror battles for crashes,
termination and HP/action invariants. Inspect win-rate and duration distributions
as tuning evidence, not as automatic proof of fun. Browser tests cover setup,
autofill, one whole match, accessibility of commands, restart/rematch and
animation-disabled play. Run the same rules under an AI controller and UI
controller to detect rule duplication.

## 8. Future Production/Training Simulator: connection points only

A future producer may emit a **versioned `BattleRoster`** containing member IDs,
type, HP, equipment/stat modifiers, commander ID and optional skill IDs. Battle
Simulator accepts and validates it as setup input; the MVP's roster editor is
just one producer. A **versioned `BattleResult`** returns survivors, injuries,
casualties and commander participation facts. Another game can consume those
records for training, replacements or reinforcements. No costs, crafting tree,
XP formula, persistent campaign or arrival schedule is specified here.

## 9. Review checklist / consistency check

- The proposed six-person side consists of **two squads of three**, so the
  action pool is three per intact squad activation and decreases with losses.
  The squad token moves collectively; front/rear are internal slots, not extra
  grid occupants. There is no separate individual movement simulation.
- The commander is a member and never grants a free extra action. Damage is
  deterministic and uses current HP/armor, not a second «survivability» stat.
- The 20-round limit guarantees completion even if both AI policies guard.
  Restart reproduces the same seed; rematch explicitly swaps sides.
- Numbers are proposed balance data. Epohi's current combat and movement
  values are neither imported nor changed. Future integration is not assumed.
- Implementation is blocked by the two decisions below; all other parameters
  are deliberately cheap to change through data or adapters.

## 10. Accepted first-experiment decisions (2026-09-30)

The user resolved the two former blockers:

- **Engine:** Godot 4 with GDScript.
- **Action grain:** hybrid. A squad activates once; its action pool at activation
  start equals its living-member count. Each member may attack at most once in
  that activation; the squad may move at most once. MOVE, ATTACK, GUARD and
  SET_FRONT each cost one action; PASS ends the activation and discards the
  remainder. Casualties before the next activation reduce its next pool. A
  casualty during an already-started activation does not retroactively remove
  an action already granted.

These are fixed for the first experiment, unlike the balance values below.

## 11. Godot implementation contract — data, state and boundaries

**Hypothesis, intended to be cheap to revise:** keep authored definitions and
mutable battle state separate.

Authored definitions are data assets: `UnitTypeDef`, `TerrainDef`,
`BattleMapDef`, `BattleBalanceDef` and `ForcePresetDef`. They contain
IDs and tunables, not battle progress. Shipped defaults are immutable during a
battle; a future tuning screen creates a runtime override/preset instead of
editing canonical defaults.

Mutable canonical state is plain domain data:
`BattleState -> SideState -> SquadState -> CombatantState`. It contains round,
initiative/activation cursor, grid positions, living/dead members, current HP,
front member, action pool/spent flags, guard status, seed/RNG state and outcome.
It must not hold Node, SceneTree, Control, animation, timer or viewport
references.

The first rules API exposes five player/AI commands: `MOVE`, `ATTACK`,
`GUARD`, `SET_FRONT`, `PASS`. Invalid commands return an error without
partial state mutation. UI and AI both obtain legal commands from the same
domain service.

State invariants checked in tests/debug validation:

- stable IDs are unique and occupied grid cells never overlap;
- current HP is within 0..max HP and dead members cannot act;
- every living squad has a living front member; manual front persists until a
  new SET_FRONT or that member dies;
- action pool never becomes negative and dead squads cannot activate;
- every scheduled living squad activates exactly once per round;
- MOVE is used at most once per activation and each member ATTACK at most once;
- battle terminates on elimination or the round cap.

A reproducible battle record carries `schema_version`, `balance_version`,
map/rosters, seed and command log. Restart replays the exact setup/seed;
Rematch preserves setup and swaps spawn sides.

## 12. Godot scene/input/map boundary

Proposed presentation tree: `Main -> Setup / Battle / Result`. Battle owns
`BoardView`, `BattleHUD` and `AnimationLayer`. No mutable battle truth is
stored in an Autoload. A small app/session service may hold navigation and the
last setup, but the domain owns battle truth.

The MVP grid uses integer coordinates, orthogonal movement, no shared
occupancy. Plain terrain costs 1, Rough costs 2 and gives 1 defensive cover;
blocked cells are impassable. Guard/Striker/Archer movement budgets remain
2/3/2 as provisional balance. A bounded flood/Dijkstra calculation determines
reachable cells. A Godot pathfinding adapter may produce candidate paths, but
the domain revalidates every path and its cost before applying MOVE.

Input is intent-based: select active squad -> show legal cells/targets ->
preview route or deterministic damage -> submit command. Presentation then
animates the already-resolved result. Animation can be skipped or disabled
without changing state or waiting on animation completion.

## 13. Baseline AI contract and deterministic tie-breaks

The first AI is intentionally explainable, not clever. It requests the same
legal commands as a human controller and scores them using balance-data weights.
Priority categories, in descending starting order:

1. legal ATTACK that kills a member;
2. ATTACK expected damage, with a small bonus for commander damage;
3. MOVE that enables a legal attack this activation;
4. MOVE reducing distance to a vulnerable enemy without entering an obviously
   worse reachable square;
5. GUARD when threatened and no useful attack remains;
6. SET_FRONT only when it increases current defensive survivability enough to
   justify an action;
7. PASS.

Exact weights are tunables, not rules. Equal scores use a stable tuple
(command type, target squad/member ID, destination y/x) and seeded RNG only
where a deliberately variable policy is being tested. Given the same state,
balance version, policy and seed, the AI must choose identically.

The AI must never inspect hidden UI state, call presentation helpers or receive
extra movement/attack privileges.

## 14. Headless balance matrix

The first batch gate is at least **10,000 deterministic headless battles**.
This is an engineering/balance diagnostic, not a requirement that every matchup
reach 50/50.

Run both maps, mirrored spawn sides, both starting-side orders and representative
two-squad compositions including homogeneous and mixed Guard/Striker/Archer
pairs. For each setup, pair seeds when sides are swapped so map/initiative
effects can be separated from policy variance.

Collect: wins/draws, first-side advantage, rounds and activations to finish,
remaining HP/members, damage by type, kills by type, commander survival,
movement/attack/guard/reorder/pass counts, wasted actions, timeout rate and
invalid-command/invariant failures.

Hard engineering gates: zero crashes, zero illegal state transitions, zero
negative action pools/HP, deterministic replay equality and termination by the
round cap. Balance findings produce tuning candidates for human playtests; they
do not silently rewrite rules.

## 15. Godot-oriented project shape for future Orca

Keep the first repository small and dependency direction obvious:

`domain/` — state, commands, rules, validation, deterministic RNG adapter  
`data/` — unit/terrain/map/balance/preset definitions and shipped assets  
`ai/` — policies/scoring using domain legal commands  
`ui/` — Setup/Battle/Result scenes, board/HUD/input adapters  
`tools/` — headless batch runner, reports and tuning helpers  
`tests/` — domain tables, replay/invariants, AI and minimal scene smoke tests

Do not introduce battalion/army gameplay yet. Preserve extension seams:
`Combatant` belongs to a squad/formation; a future battalion can own squad IDs,
and an army can own battalion IDs. Higher levels must define their own
activation budget explicitly rather than multiplying lower-level actions
implicitly.

Production/Training remains outside this MVP. Its future interface is the
versioned `BattleRoster` input and `BattleResult` output already described
above.


## 16. Godot bootstrap, validation and build workflow

This section is an **implementation plan**, not gameplay code. It closes the
remaining engine/bootstrap questions while preserving the pure-domain boundary.

### Project bootstrap and entry points

**Design choice:** use one Godot 4 GDScript project with these explicit entry
paths:

- normal launch: `Main.tscn` -> Setup -> Battle -> Result;
- domain tests: scripts under `tests/` that instantiate no Battle/UI scene;
- batch balance: `tools/batch_simulator.gd`, invoked headlessly and given a
  preset, seed range and output path;
- replay/debug: `tools/replay_battle.gd`, consuming a versioned battle record.

`Main.tscn` owns screen transitions only. Battle truth remains in domain
objects. Autoloads are limited to genuinely application-wide services such as
settings/version metadata; **BattleState, RNG and active-match controllers are
not Autoload singletons**. This prevents tests and rematches from inheriting
hidden mutable state.

### Resource/file naming contract

Keep authored definitions under `res://data/` and runtime logic under
`res://domain/`. Starting names:

`unit_types/*.tres` -> `UnitTypeDef`; `terrain/*.tres` -> `TerrainDef`;
`maps/*.tres` -> `BattleMapDef`; `balance/default.tres` ->
`BattleBalanceDef`; `forces/*.tres` -> `ForcePresetDef`.

Every definition has a stable string ID independent of filename/display text.
Runtime records store IDs and scalar state, not Node/resource object identity.
Renaming art or scenes therefore does not invalidate deterministic records.

### Validation gates

Startup/dev validation must fail clearly for duplicate IDs, unknown referenced
IDs, invalid map dimensions/spawns, overlapping blocked/spawn cells, negative
movement/range/HP, malformed formations, or tuning bounds where
`min > default > max`. A battle setup is validated again before
`create_battle`; invalid data never enters canonical state.

### Headless and deterministic workflow

The batch runner constructs the same immutable definitions and pure rules used
by the UI but never loads `Battle.tscn`. Inputs are explicit:
`balance_version + map_id + rosters + controller policies + seed(s)`.
Output includes aggregate CSV/JSON plus enough failing-case metadata to replay a
specific seed. No simulation result may depend on frame rate, wall-clock time,
animation completion, node order, OS locale, or global random calls.

**Starting performance hypothesis:** 10,000 tiny 9x7 MVP battles should be a
routine offline balance job, but no wall-clock threshold is a gameplay
requirement until measured on the development machine. First optimize only if
profiling identifies a real bottleneck. Keep batch execution single-process
initially; parallel workers are an extension, not an MVP dependency.

### Test pyramid and implementation gates

1. **Domain gate:** table tests for action economy, movement/path costs,
   targeting/front replacement, damage/armor/guard/cover, death, activation
   scheduling and end conditions.
2. **Determinism gate:** identical setup/seed/commands produces byte-equivalent
   normalized final state and outcome; restart reproduces it.
3. **Invariant/fuzz gate:** seeded AI-vs-AI battles never produce negative
   actions, illegal occupancy, dead activations or non-termination beyond the
   round cap.
4. **AI gate:** policy always chooses from `legal_commands`; deterministic
   tie-breaks reproduce the same command sequence.
5. **Scene smoke gate:** Setup can create a valid battle, Battle can consume
   domain events, Result can restart/rematch, and animation-disabled mode
   completes without changing results.
6. **Balance evidence gate:** run the documented >=10,000 mirror matrix and
   save distributions; do not convert statistical symmetry into a hard
   assertion that forces balance hacks.

A change to UI/art should not require rerunning balance logic beyond smoke
coverage; a rules/balance change reruns domain, determinism, invariants and the
relevant batch matrix.

### Export/build workflow

**First target hypothesis:** desktop development build, Windows first. Keep the
project exportable to other Godot-supported desktop targets by avoiding
platform-specific gameplay dependencies. Configure export presets in source
control once implementation begins; produce a debug/playtest export before any
release-oriented packaging. Web export is optional evidence later, not an MVP
acceptance condition and not an Epohi integration strategy.

The build checklist is: validate definitions -> run domain/determinism tests ->
run focused AI/invariant batch -> launch scene smoke -> export playtest build ->
record build/version plus balance version. Large balance batches may run
separately because they are tuning evidence rather than a prerequisite for
every UI iteration.

### Orca implementation order / acceptance gates

When implementation is authorized, Orca should work in dependency order rather
than inventing design while coding:

1. bootstrap project + definition/state schemas; gate = validation fixtures;
2. pure command legality/state transitions; gate = domain tests green;
3. deterministic scheduler/RNG/replay; gate = replay/invariants green;
4. baseline AI + headless runner; gate = reproducible AI-vs-AI batch;
5. minimal Setup/Battle/Result UI adapters; gate = complete animation-off match;
6. tuning resources/presets and balance report; gate = mirror matrix produced;
7. presentation polish/export; gate = Windows playtest build and restart/rematch
   smoke.

Do not add battalion/army, production/training, persistence, procedural maps,
networking, Epohi integration, or a second combat formula while satisfying
these gates. Those are explicit extension points after human playtesting.

## 16. Design checkpoint

Current provisional numbers remain centralized and reversible: 9x7 maps; two
squads x three members per side; Guard 12/3/4 HP/armor/power, Striker 9/1/6,
Archer 8/0/5; commander +2 HP/+1 power; rear ranged attack -2 power; movement
2/3/2; Plain cost 1, Rough cost 2/+1 cover; 20-round cap.

Final audit: the Godot bootstrap/export/headless/test workflow, exact
resource naming, implementation order and Orca acceptance gates are now
specified above. No unresolved contradiction was found with the accepted pure
domain/state, deterministic RNG, hybrid activation, data-driven tuning or
future hierarchy boundaries.

**Implementation readiness:** the first experiment is design-complete enough to
start once the user explicitly authorizes implementation. Further autonomous
paper-design passes should stop here. Human playtesting, not additional design
polish, should drive subsequent combat/balance changes.

## USER DECISIONS NEEDED

**None before the first MVP.** Godot 4/GDScript and hybrid squad activation are
accepted. All remaining numeric values and baseline AI weights are explicitly
reversible tuning hypotheses. A new user decision is needed only if later work
would materially change the intended combat feel or make an expensive
architectural commitment.
