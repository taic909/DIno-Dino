# Dino Game: Next Chat Handoff

Use this file to resume development without reconstructing the recent work from chat history. `GAME_REFERENCE.md` remains the source of truth; read it completely before planning or editing. Then read `DEV_MODE_REFERENCE.md`, `GODOT_CODE_LIBRARY.md`, and the current scripts/scenes named below.

## Current milestone

Phase 1 is still the only active phase. The goal is satisfying movement and one satisfying enemy interaction. Do not add portals, dialogue, inventory, saving, bosses, health/checkpoint progression, artifact systems, or final art. Prototype health/contact feedback exists, but death and checkpoints are intentionally not implemented.

## Latest completed update

- The player now uses generated two-frame sheets for grounded running, lateral Tail Swipe, and downward/front-flip Tail Swipe. The corrected run sheet is `archeopteryx-run-2f-v2.png`; it has an alternating stride plus exported per-frame offsets that stabilize its anchor. Each attack animation is selected through its already-separate attack path; the existing idle/air and Glide sprites remain in use.
- Preliminary placeholder sounds now play for jump, landing, Glide start, Pounce, Tail Swipe, player damage, enemy stun, enemy Tail Swipe damage, and enemy defeat. The generated WAV files live in `assets/audio/` and are intentionally temporary.
- Lateral and downward Tail Swipe now have separate `Area2D` hitboxes, separate convex semicircle shapes, and separate `Line2D` indicators.
- Only the attack-specific pair is enabled and shown. The existing lateral line keeps the user's scene tuning; the new downward line is a clean vertical 82-pixel indicator.
- Both attack hitboxes currently share damage response code, but the scene nodes are separate so future lateral and downward animations can be implemented independently.
- Glide-Pounce enemy rebounds now retain 90% of the speed from before the Pounce multiplier and cap at 560. Both values remain exported as `glide_pounce_momentum_retention` and `glide_pounce_rebound_speed_cap`.
- A focused headless test passed for lateral/downward hitbox and indicator separation, 90% Glide-Pounce retention, and the 560 cap. The temporary test file was removed.

## Exact controls

| Action | Controller | Keyboard / mouse |
| --- | --- | --- |
| Move | Left stick or D-pad | A / D |
| Glide pitch | Stick up climbs; stick down dives | W climbs; S dives |
| Jump / start or cancel Glide | A / Cross | Space |
| Pounce | LB / L1 | E or left mouse |
| Tail Swipe | RB / R1 | Q or right mouse |
| Downward Tail Swipe | Hold down as the dominant direction, then Tail Swipe | Hold S as the dominant direction, then Q or right mouse |
| Pause | Menu / Options | Escape |
| Dev overlay | Right-stick click | F3 |
| Reset room while dev overlay is visible | View / Create | R |

Glide starts only on a fresh second Jump press while airborne. A Glide Pounce stays in Glide, rebounds upward from an enemy, preserves momentum, and restores at least the exported Glide refill amount.

## What to playtest now

1. Use a lateral Tail Swipe on both sides of the player. Confirm the forward line and forward semicircle follow the facing direction, with no downward line visible.
2. Hold down and Tail Swipe while airborne. Confirm only the vertical line appears, the downward semicircle hits the enemy below, and a hit bounces the player upward.
3. Build Glide speed with a dive, Pounce into an enemy, and confirm the rebound carries noticeably more speed than before while staying controllable.
4. Repeat fast Glide-Pounce rebounds and confirm speed does not grow without limit.
5. Confirm Pounce, Glide, pause/rebinding, contact damage, and the F3/right-stick dev overlay still behave normally.

## Files and connections

- `scripts/player_controller.gd`: movement, Glide, Pounce, Tail Swipe selection, contact damage, and feedback. Current notable defaults include `max_speed = 300`, `jump_velocity = -1000`, `glide_duration = 5`, Glide-Pounce retention `0.9`, and rebound cap `560`. Preserve actual current values unless playtesting justifies a change.
- `scenes/player/player.tscn`: player collision nodes, the user-authored Hurtbox polygon, both Tail Swipe hitbox/indicator pairs, and current sprite assignments. Do not replace the user-tuned lateral indicator or Hurtbox polygon.
- `scripts/practice_dummy.gd`: stun, Tail Swipe damage, defeat, hit feedback, and contact-damage reporting.
- `scripts/dev_mode.gd`: F3/right-stick overlay including position, velocity, health, Glide, and Pounce state.
- `GAME_REFERENCE.md`: source of truth and confirmed decision log.
- `GODOT_CODE_LIBRARY.md`: current controls and implementation notes.
- `DEV_MODE_REFERENCE.md`: developer controls and rebinding workflow.

## Working-tree cautions

The working tree contains useful uncommitted gameplay changes from the recent sessions. It also contains the user's sprite reorganization: tracked archeopteryx v1/v2 files are deleted and `assets/sprites/Archive/` is untracked. Preserve these changes and inspect actual files instead of assuming `git diff` is a complete baseline. Do not modify `scenes/main.tscn` or shorten the user's map.

The user requires every new or changed non-variable GDScript line to have a short comment describing what it does. Variable definitions do not need comments. Use typed, readable GDScript and keep gameplay tuning exported in the Inspector.

## Suggested next small step

Playtest the split Tail Swipe presentation and stronger Glide-Pounce carry before adding more behavior. If the split works, the next coherent step is to connect distinct temporary lateral/downward attack visuals or animations to the two existing paths without building a general combat framework.
