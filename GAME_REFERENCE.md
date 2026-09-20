# Project Fossilheart: Source of Truth

> **Purpose:** Give any new Codex task the minimum complete context needed to work on the game without reading prior conversations.
>
> **Authority:** Read this file before planning or editing. If older project notes conflict with it, this file wins. Preserve existing user files unless a change is necessary and explained.

## One-sentence pitch

A cute, scrappy feathered dinosaur travels into several wildly different futures, steals back strange technologies, and turns movement itself into a weapon while trying to stop the deliberately caused asteroid impact that erased its world.

## Player promise

The player should feel small, quick, clever, and increasingly capable. Simply crossing a room should be satisfying. Combat should reward using momentum, positioning, rebounds, grapples, terrain, and future artifacts rather than standing still and repeatedly attacking.

## Design pillars

1. **Movement is the main weapon.** Traversal and combat share the same verbs.
2. **Cute, scrappy, and epic.** The hero is charming and vulnerable without making the stakes trivial.
3. **Deliberate combat with bursts of speed.** Read the situation, choose a line, then act quickly.
4. **Artifacts create expression, not key-shaped locks.** Each upgrade should support traversal, combat, and advanced combinations.
5. **Distinct futures, connected consequences.** Every future era has its own identity and changes what the player can do in the prehistoric world.
6. **Easy to begin, deep enough to speedrun.** Forgiving input handling and moderate default difficulty should coexist with momentum conservation, shortcuts, cancels, and mastery.

## Confirmed creative direction

| Area | Decision |
| --- | --- |
| Tone | Funny, epic, cute, and slightly cozy |
| Content | Family-friendly adventure |
| Hero | Fictional small feathered dinosaur; cute but scrappy |
| Dialogue | The dinosaur may speak eventually, but dialogue is not needed for the prototype |
| Accuracy | Gameplay and style take priority over scientific accuracy |
| Priorities | 1. Movement/platforming, 2. collecting/upgrading abilities, 3. combat |
| Combat | Movement is the primary offense; close-range attacks are the fallback |
| Difficulty | Moderate by default, with optional difficulty/accessibility settings later |
| Controls | Controller-first, while remaining fully playable with mouse and keyboard |
| Death | Restart at a nearby checkpoint; avoid punishing resource loss for now |
| Ability limits | Timing and short cooldowns, not consumable ammunition |
| Mastery | Advanced techniques should support speedrunning |
| Revisiting | Earlier areas are revisited occasionally, mainly for secrets |
| Initial target | A polished-feeling prototype of roughly 20 minutes |
| First success test | Movement feels satisfying and defeating one enemy feels satisfying |
| Long-term goal | Potential public release; build quality comes before marketing |
| Developer | Beginner programmer on a Windows desktop; roughly 5–10 hours per week |
| References | *Tron*, *The Land Before Time*, *Silksong*, *Terraria*, and *Jurassic Park* |
| Music | Each era should have its own musical identity |

References describe desired ingredients, not assets or mechanics to copy. The game needs its own silhouettes, controls, world logic, terminology, and visual identity.

## Narrative foundation

- In the distant future, a sympathizer discovers that the dinosaurs' extinction was intentional rather than a natural accident.
- The sympathizer sends the protagonist through time and gives it a chance to alter the outcome.
- The dinosaur must retrieve objects from multiple futures and use them in the prehistoric era to destroy or redirect the asteroid.
- Only a few characters should appear, but each should be memorable.
- Someone or something benefits from the extinction and acts as the central opposing force.
- The precise antagonist, the sympathizer's identity, and the rules for changing the past remain open.
- Multiple endings are not a current priority.

### Narrative questions to postpone

These are deliberately unresolved and must not block the movement prototype:

- Why does dinosaur extinction benefit the antagonist?
- Did the antagonist launch the asteroid, redirect it, or prevent an earlier defense?
- Is the sympathizer human, artificial intelligence, post-human, alien, or something stranger?
- Does changing the past rewrite a future immediately, create branches, or preserve a fixed timeline?
- Why can this dinosaur safely use the portals and artifacts?

## Recommended world structure

Use a **hybrid structure**:

- The prehistoric era is the large, interconnected home world and contains roughly 60–70% of the finished game.
- Unstable portals lead to compact future expeditions, together comprising roughly 30–40% of the game.
- A future expedition is shorter than a major prehistoric region, but it must not feel like a disposable challenge room.
- Each future must contain at least one defining movement idea, one important story discovery, one striking landmark or set piece, and one artifact or artifact evolution.
- Returning with an artifact opens new routes in the prehistoric world. Larger story milestones may also produce visible environmental changes there.
- Revisits to a completed future should be optional and used mainly for secrets, mastery challenges, or character follow-ups.

This preserves an interconnected Metroidvania-like world while allowing dramatic shifts in art, music, enemies, and mechanics. It also keeps the production scope manageable.

### Desired future eras

- Near-future overgrown city
- Engineered fungal ecosystem
- Lunar colony
- Civilization governed or inhabited by artificial intelligence
- Interstellar ship

Do not build all five for the first prototype. The prototype should use one tiny future micro-zone at most.

## Core gameplay loop

1. Explore the prehistoric world and discover an obstacle, threat, portal, or clue.
2. Enter a compact future expedition.
3. Learn that era's movement/combat idea and retrieve an artifact.
4. Return to prehistory with a new expressive verb.
5. Use that verb to defeat enemies, reveal secrets, and reach a new region.
6. Gradually assemble a way to intercept or redirect the asteroid.

## Baseline player kit

The protagonist should feel good before collecting an artifact.

- Responsive run with acceleration and intentional stopping
- Variable-height jump
- Coyote time and jump buffering
- Useful but controlled air steering
- A 5-second airborne glide started by a second Jump press in the air, with conventional vertical-stick pitch, dive-scaled acceleration, and momentum inherited from jumps, Pounces, and rebounds
- Glide visuals pitch with the movement arc while normal airborne movement and the upright collision shape remain stable
- Clear landing, turnaround, and hit feedback
- A movement attack tentatively called **Pounce**
- A quick, short-range fallback attack called **Tail Swipe**

### Prototype combat hypothesis

**Pounce** is a short horizontal burst that preserves vertical momentum and follows a shallow arc under reduced gravity. Outside Glide, its horizontal speed is fixed and predictable. During Glide, its horizontal speed is calculated by multiplying the dinosaur's current overall speed, rewarding built-up momentum. It does not deal direct damage; striking an enemy stuns it and rebounds the dinosaur. A Pounce started during Glide remains in the Glide state and keeps the Glide artwork; its timer pauses during the short burst, then resumes afterward. Enemies act like rounded bounce surfaces: off-center hits launch the dinosaur upward and away, while a centered hit from directly above launches it vertically. Rebound strength uses the speed from before the Pounce multiplier and has a separate cap, preventing repeated hits from multiplying momentum indefinitely. The current defaults retain 90% of approach speed and cap the rebound at 560. A successful hit restores an independently tunable amount of Glide time rather than the full Glide duration, allowing controlled glide-pogo chains even when the total duration is increased.

**Tail Swipe** is safer and easier but has close range and little mobility. A lateral Swipe cancels Glide without changing the dinosaur's existing velocity; momentum changes only after hitting an enemy, which produces a controlled recoil away from it. The downward version preserves horizontal speed but briefly softens vertical movement for aiming, then bounces the dinosaur upward when it connects. Tail Swipe damages enemies directly: the practice dummy takes two ordinary Swipes, or one Swipe while stunned by Pounce. Lateral and downward Swipes each have their own 82-pixel semicircular hitbox and line indicator so they can receive different art and animation later. Only the matching hitbox and indicator are active during a Swipe.

The first enemy should communicate a clear opening, react strongly to a successful hit, and die in a way that makes momentum and impact obvious. Start with one excellent interaction rather than several enemy types.

For prototype collision, keep the player environment collider, player Hurtbox, enemy hurtboxes, and attack hitboxes separate and simple. The player Hurtbox takes prototype contact damage when it overlaps an enemy. The active Pounce hitbox stuns the practice dummy, while distinct lateral and downward Tail Swipe hitboxes damage it.

## Artifact design rules

An artifact is worth developing only if it:

1. Adds a traversal verb and a combat use.
2. Is understandable within a few attempts but supports advanced techniques.
3. Produces readable visual, sound, and controller feedback.
4. Combines with existing movement rather than replacing it.
5. Can create interesting level geometry, enemies, or secrets.
6. Has a recognizable origin in its future era.
7. Avoids being merely a colored key, passive stat increase, or ordinary weapon reskin.

### Current candidates—not yet selected

- **Living Tether:** A fungal or biomechanical grapple that can swing the player, pull light enemies, pull the dinosaur toward heavy enemies, and create rebound lines between anchor points. This is currently the player's favorite direction.
- **Phase Molt:** A dash that leaves behind a temporary shed skin. The dinosaur can return to it, strike through the space between positions, or use it as a recovery point.
- **Gravity Seed:** A placed miniature gravity source used for swinging, slingshots, grouping enemies, and curving projectiles.
- **Kinetic Tail Coil:** Stores energy from falls, parries, or impacts and releases it through launches, tail strikes, or shockwaves.
- **Echo Recorder:** Repeats a short recording of the player's movement and attacks, enabling crossing attacks, puzzles, and advanced route planning.
- **Nanite Jaw:** Bites material from selected future objects and spits it as a projectile, temporary foothold, bounce surface, or armor-breaking tool.
- **Polarity Fang:** Attracts or repels the dinosaur from metal, enables rail movement, and redirects mechanical enemies or projectiles.
- **Weather Capsule:** Creates a small controllable cloud that can lift, freeze into a platform, conduct electricity, or interact with other abilities.
- **Solar Sail:** Enables air braking, current riding, diving attacks, and projectile redirection without functioning as a generic double jump.
- **Momentum Vessel:** Captures the speed and direction of one action, then releases that stored movement later as a launch or impact.
- **Hard-Light Thread:** Stitches two points together to create a temporary rail; the dinosaur can grind along it while damaging enemies placed on the route.
- **Swarm Feather:** Releases a small group of future micro-drones that briefly form a midair step, directional shield, or diving strike depending on player input.

Before committing to the first artifact, prototype at least three candidates as crude mechanics in a test room. Evaluate each for fun, readability, combination potential, and level-design cost. The Living Tether should be one of the three.

## Technical direction

### Engine decision: Godot 4

Use Godot 4 and typed GDScript for this project.

Reasons:

- Godot's 2D workflow is a strong match for the game.
- GDScript is concise and approachable for a beginner.
- Fast iteration matters more here than access to a larger commercial ecosystem.
- Godot can support future 3D learning and smaller 3D projects. A hypothetical future 3D game does not justify making this project harder today.
- The existing folder is already a functioning Godot project with a basic player controller and test scene.

Reconsider the engine only for a separate future project with requirements Godot cannot meet. Do not restart this game in Unity merely as preparation for possible 3D work.

### Readability rules

- Use typed GDScript.
- Give files, nodes, functions, inputs, and variables descriptive names.
- Keep tunable values exported and grouped in the Inspector.
- Prefer short functions that describe intent.
- Add a short comment to every non-variable code line explaining what it does; variable definitions do not require comments.
- Avoid unexplained numbers inside gameplay logic.
- Keep scenes small and composable.
- Do not introduce a framework, service layer, or component system until a concrete need exists.
- Do not split one simple behavior across many tiny files merely to appear organized.
- If a script grows difficult to navigate, extract a coherent responsibility and document the boundary.
- Preserve a short practical learning note for new GDScript concepts the user may want to edit later.
- Make one system change at a time, test it, and explain how the relevant files connect.

### Current repository state

The project already contains:

- `project.godot`
- A basic `CharacterBody2D` player scene
- A basic run/jump controller with acceleration, coyote time, jump buffering, variable jump height, and stronger fall gravity
- A gray-box main scene with platforms
- Temporary dinosaur art
- A small developer overlay with live movement readouts and rapid room reset
- A pause menu with persistent keyboard, mouse, and controller rebinding
- `README.md` and `GODOT_CODE_LIBRARY.md`

Treat this as an early prototype to inspect, not as disposable code and not as final architecture. Reuse what is clear and helpful. Replace something only when the new task can name the reason.

## Development plan

### Phase 1: Feel test—current priority

Goal: movement feels satisfying and killing one enemy feels satisfying.

Build only:

- A compact gray-box movement course
- Tuned run, jump, fall, and landing behavior
- Pounce prototype
- Tail Swipe prototype
- One stationary or very simple enemy/dummy
- Hit detection, damage, knockback/rebound, hit pause, particles or simple visual burst, and sound placeholders
- Instant room reset for rapid testing
- Keyboard controls plus a basic controller mapping

Do not build portals, dialogue, inventory, saving, final art, bosses, or a generalized ability framework in this phase.

**Exit test:** The player voluntarily repeats jumps and enemy hits because they feel good, not merely because the mechanics function.

### Phase 2: One real enemy and checkpoint loop

- Give one enemy a readable patrol or attack pattern.
- Add player health, damage response, invulnerability feedback, death, and nearby checkpoint restart.
- Construct a five-minute challenge that teaches movement combat without text.
- Add the first optional difficulty/accessibility variables only where actual testing shows a need.

### Phase 3: Artifact bake-off

- Build crude versions of the Living Tether and two other artifact candidates in a dedicated test room.
- Use placeholder visuals and identical evaluation rooms where possible.
- Compare traversal fun, combat use, skill ceiling, clarity, bugs, and level-design workload.
- Select one artifact only after hands-on testing.

### Phase 4: Twenty-minute vertical slice

- A small prehistoric route with a checkpoint and secrets
- One unstable portal
- One very small future micro-zone with a distinct look and sound
- One memorable future character or message from the sympathizer
- One polished artifact acquisition
- A return route that demonstrates how the artifact changes prehistoric exploration and combat
- A short climactic encounter using the learned mechanics

### Phase 5: Evaluate before expanding

Playtest the slice. Decide whether the movement, combat, premise, and production process justify a larger game. Only then plan all eras, final art production, save structure, dialogue tools, and the full world map.

## Working method for Codex tasks

- Keep this file as the source of truth.
- Use one implementation task for the active milestone rather than creating a new task for every small feature.
- Give agents bounded, non-overlapping jobs such as reviewing movement math, testing a finished mechanic, or researching controller accessibility.
- Do not let multiple agents edit the player controller simultaneously.
- At the end of a milestone, update the confirmed decisions and current phase in this file.
- Each implementation handoff should list changed files, explain how they connect, give exact controls, and state how the user can verify the result.
- Prefer a small verified change over a large batch of untested systems.

## Prompt for the next implementation task

Copy the following into a new Codex task opened in this project folder:

> Read `GAME_REFERENCE.md` completely before making changes; it is the project's source of truth. Then inspect the existing Godot project and preserve useful work. Begin Phase 1 only. First run or otherwise validate the current movement sandbox, then improve it in small, testable steps toward the Phase 1 exit test: satisfying movement and one satisfying enemy kill. Implement the smallest coherent step, verify it, and explain what changed in beginner-friendly language. Keep typed GDScript readable, avoid premature architecture, do not build later-phase systems, and do not wait for story decisions that the reference marks as unresolved. Update documentation only when a confirmed decision or implemented control changes.

## Immediate decision log

- **2026-09-19:** Chose Godot 4 with typed GDScript.
- **2026-09-19:** Recommended a prehistoric interconnected main world plus compact future expeditions.
- **2026-09-19:** Defined the first prototype success test as satisfying movement plus one satisfying enemy defeat.
- **2026-09-19:** Kept the first artifact open pending a three-mechanic bake-off; Living Tether must be included.
- **2026-09-19:** Confirmed controller-first controls with mouse-and-keyboard play remaining fully supported.
- **2026-09-19:** Added an expandable developer overlay and persistent in-game control rebinding for prototype iteration.
- **2026-09-19:** Added a baseline airborne Glide; the current user-tuned duration is 2 seconds, with faster acceleration and a slightly higher speed than running.
- **2026-09-19:** Changed airborne Pounce to preserve vertical momentum and use reduced gravity instead of locking movement perfectly horizontal.
- **2026-09-19:** Integrated dedicated glide artwork and visual rotation that is active only while gliding; normal jumps, Pounces, and rebounds remain visually upright.
- **2026-09-19:** Split environment, enemy, and Pounce collision into simple dedicated shapes so attack reach is independent from platform collision.
- **2026-09-19:** Changed Glide to preserve entry momentum and use player-controlled pitch; steeper dives accelerate harder and shallow glides accelerate gently.
- **2026-09-19:** Moved Glide pitch to inverted left-stick controls (up dives, down climbs), mirrored by W/S on keyboard.
- **2026-09-19:** Changed Pounce from direct damage to a temporary stun. Glide Pounces preserve part of their momentum, rebound upward, refill Glide time, and can be chained.
- **2026-09-19:** Changed Glide activation to require a fresh second Jump press while airborne; holding the original jump no longer activates it. With no pitch input, Glide settles toward a shallow downward angle.
- **2026-09-19:** Split Pounce launch speed into two modes: a fixed speed outside Glide and a multiplier of current overall speed during Glide.
- **2026-09-19:** Made Glide Pounce preserve the active Glide state and artwork, pausing the Glide timer during the burst and resuming it afterward.
- **2026-09-19:** Changed Glide to conventional pitch controls (up climbs, down dives), removed the pitch-angle limits, and made enemy Glide-Pounce rebounds behave like upward-launching domes with vertical rebounds at top center.
- **2026-09-19:** Bounded Glide-Pounce rebound momentum using pre-Pounce speed and a separate rebound cap. Successful hits now restore the exported Glide refill amount instead of the full, independently tunable Glide duration.
- **2026-09-19:** Implemented Tail Swipe as a close-range damage/finisher attack that sheds momentum; stunned practice dummies are defeated in one Swipe and unstunned dummies in two.
- **2026-09-19:** Fixed the developer overlay so F3 shows it on the first press and added right-stick click as a controller toggle.
- **2026-09-19:** Changed Tail Swipe aiming from behind the dinosaur to forward-or-down directional aiming and added a temporary line indicator aligned with its hitbox.
- **2026-09-19:** Extended Tail Swipe reach to 82 pixels and replaced its rectangular attack area with a rotating semicircular hitbox.
- **2026-09-19:** Removed Tail Swipe's universal startup momentum loss. Lateral Swipes preserve velocity until an enemy hit causes recoil; downward Swipes keep a vertical-only stutter and bounce upward on contact.
- **2026-09-19:** Wired the user-authored player Hurtbox polygon to enemy contact damage with three prototype health points, knockback, a damage flash, and brief invulnerability; death and checkpoints remain unimplemented.
- **2026-09-19:** Added a gradual post-Glide air state so canceling or exhausting Glide preserves overspeed momentum and bleeds it off instead of clamping abruptly.
- **2026-09-19:** Adopted the project rule that every new or changed non-variable code line receives a short explanatory comment.
- **2026-09-19:** Split lateral and downward Tail Swipe into separate hitboxes and indicators so each attack can receive distinct animation and presentation later.
- **2026-09-19:** Increased default Glide-Pounce rebound carry to 90% of approach speed and raised its safety cap to 560.
- **2026-09-20:** Integrated two-frame sprite sheets for grounded running, lateral Tail Swipe, and downward front-flip Tail Swipe while preserving separate attack hitboxes.
