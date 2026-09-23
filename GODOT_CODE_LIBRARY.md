# Godot Code Library

This is the project's practical GDScript reference. It records code we have actually used, what it means, and where it belongs. New sections will be added as the game grows.

## Script structure

```gdscript
extends CharacterBody2D
```

`extends` gives a script the abilities of a Godot node type. This controller extends `CharacterBody2D`, so it receives properties such as `velocity` and methods such as `move_and_slide()`.

```gdscript
func _physics_process(delta: float) -> void:
	pass
```

`func` declares a function. Godot calls `_physics_process` at a fixed rate for physics. `delta` is the elapsed time in seconds. `-> void` means the function does not return a value. `pass` means "do nothing" and is useful while a function is empty.

## Variables and types

```gdscript
var coyote_timer := 0.0
var direction := Input.get_axis("move_left", "move_right")
```

`var` creates a value that can change. `:=` asks Godot to infer its type from the value on the right.

```gdscript
@export var max_speed := 240.0
```

`@export` displays a variable in the Inspector. This lets us tune movement without rewriting code.

```gdscript
@onready var sprite: Sprite2D = $Sprite2D
```

`@onready` waits until the scene is ready. `$Sprite2D` finds the child node named `Sprite2D`. `: Sprite2D` states the expected node type.

## Input

```gdscript
var direction := Input.get_axis("move_left", "move_right")
```

Returns `-1.0` for left, `1.0` for right, and `0.0` for neither or both.

```gdscript
Input.is_action_just_pressed("jump")
Input.is_action_just_released("jump")
```

These are true for one frame when an input action starts or ends. Input action names are configured in **Project > Project Settings > Input Map**.

## Conditions

```gdscript
if is_on_floor():
	coyote_timer = coyote_time
else:
	coyote_timer = maxf(coyote_timer - delta, 0.0)
```

`if` runs code when its condition is true. `else` runs when it is false. Indentation shows which lines belong to each branch.

```gdscript
if direction != 0.0:
	sprite.flip_h = direction < 0.0
```

`!=` means "is not equal to." `<` means "is less than." The comparison on the right produces either `true` or `false`.

## Movement

```gdscript
velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
```

`move_toward` changes a number toward a target by a limited amount. Here it creates smooth acceleration and stopping.

```gdscript
velocity.y += gravity * delta
```

`+=` adds to the current value. Positive Y points downward in Godot 2D, so positive gravity makes the player fall.

```gdscript
move_and_slide()
```

Moves a `CharacterBody2D` using its `velocity`, resolves collisions, and updates checks such as `is_on_floor()`.

## Collision shapes and hitboxes

A player `CollisionPolygon2D` should be a direct child of the `CharacterBody2D` and use **Build Mode: Solids**. **Segments** creates separate outline edges instead of a solid body; on a player collider, that can prevent `is_on_floor()` from staying true and cause visible vibration as the body repeatedly falls into and is pushed out of the floor.

The current prototype uses separate, simple collision roles:

| Collision | Node type | Purpose |
| --- | --- | --- |
| Player environment collider | `CollisionShape2D` with a capsule | Floors, platforms, and walls only |
| Player Hurtbox | `Area2D` with the user-tuned polygon | Detects enemy contact damage without changing environment collision |
| Enemy hurtbox | `Area2D` with a rectangle | A target that attacks can detect |
| Pounce hitbox | `Area2D` with a rectangle | Enabled only during Pounce; detects enemy hurtboxes |

Keeping the attack hitbox separate means touching an enemy normally does not count as an attack, and changing attack reach does not change how the player stands on platforms.

## Calling our own functions

```gdscript
func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
```

A large task can be split into smaller named functions. A leading underscore is a convention meaning the function is intended for use inside this script.

## Useful operators

| Syntax | Meaning |
| --- | --- |
| `=` | Assign a value |
| `:=` | Assign and infer the type |
| `+=` | Add and save the result |
| `*=` | Multiply and save the result |
| `==` | Is equal to |
| `!=` | Is not equal to |
| `>` / `<` | Greater than / less than |
| `and` | Both conditions must be true |
| `or` | At least one condition must be true |
| `not` | Reverse true and false |

## Current controls

The game is controller-first, while keeping complete keyboard controls for the current movement sandbox.

The game window now opens at 1920 × 1080. Its 1152 × 648 logical canvas preserves existing room coordinates. To change the default player-camera view, open `scenes/player/player.tscn`, select `Camera2D` under `Player`, and edit its `Zoom` property (currently `Vector2(0.5, 0.5)`). In the live level editor, use the mouse wheel over the world, + / −, or the dock's Camera buttons to change that character-following zoom during play.

| Action | Controller | Keyboard |
| --- | --- | --- |
| Move | Left stick or D-pad | A / D |
| Glide Climb | Left stick up or D-pad up | W |
| Glide Dive | Left stick down or D-pad down | S |
| Jump / Glide | Bottom face button (A on Xbox, Cross on PlayStation) | Space |
| Pounce | Left shoulder button (LB on Xbox, L1 on PlayStation) | E or left mouse button |
| Tail Swipe | Right shoulder button (RB on Xbox, R1 on PlayStation) | Q or right mouse button |
| Pause | Menu / Options | Escape |
| Developer Flight Mode | X / Square | F5 |

Open **Pause > Controls** to replace keyboard/mouse and controller bindings independently, including the Dev Mode toggle. Navigate menus with the D-pad or left stick and select with A / Cross. Changes are saved in Godot's per-user data folder, not in the project files. Use **Restore Defaults** to return to the bindings above.

Tap or hold the first Jump press to control jump height. Release it, then press Jump again while airborne to start a Glide lasting up to 5 seconds; holding the original jump does not activate Glide. Pressing Jump again cancels an active Glide. Canceling or exhausting Glide keeps the current air velocity and uses `glide_exit_drag` to reduce excess horizontal speed gradually; ordinary air movement resumes after the minimum exit time and once speed returns to the running range. The Glide timer resets when the player lands. A stationary Glide starts at walking speed (300 by default), while same-direction travel preserves faster horizontal speed; upward or downward jump speed is not converted into forward momentum. If you cancel, turn around, and Glide again, old-direction speed is discarded and the new Glide builds to walking speed over a short ramp. Tune that ramp with `glide_reverse_acceleration` in the Player Inspector (1800 by default). Glide uses conventional flight controls: push the left stick up or press W to climb, and push it down or press S to dive. With no pitch input, the dinosaur gradually settles into a shallow descent. Glide speed follows gravity projected along the chosen flight angle: level travel receives no gravity acceleration, downward angles continuously gain speed, a 90-degree dive receives full gravity, and climbing spends momentum. The remaining `glide_max_speed` value is a high 1400 safety limit rather than the normal target speed. Outside Glide, Pounce uses a fixed launch speed. During Glide, Pounce launch speed is a multiplier of current speed, the Glide artwork remains active, and the Glide timer pauses during the burst. Enemy rebounds use the pre-Pounce speed, retain 90%, and cap at 560 by default. A successful hit ensures at least `glide_pounce_refill_time` remains—1.25 seconds by default—without refilling the entire `glide_duration`. These values are exported separately in the Player Inspector.

Terrain impacts end the active Glide without restoring its old speed. Wall and ceiling hits within 20 degrees of parallel bounce with reduced speed; direct hits bounce with a larger speed penalty. In the Player Inspector, `glide_surface_glance_max_angle` controls that angle, `glide_surface_glance_speed_retention` controls shallow-bounce speed, and `glide_hard_impact_speed_retention` controls direct-hit speed. Landings retain horizontal speed according to `glide_ground_impact_speed_retention`, then ease toward walking speed using `glide_ground_momentum_drag` and `glide_ground_momentum_time`. These values use the collision normal from `move_and_slide()`, not the sprite's rotation.

The player Hurtbox detects enemy layer 2. Practice-dummy or beetle contact removes one prototype health point, applies knockback and a red flash, then grants 0.6 seconds of contact invulnerability. Current health appears in dev mode; player death is not implemented yet.

The reusable `WalkerBeetle` scene is a slightly larger green enemy in the main movement sandbox. Its `Area2D` is both the attack target and touch-damage source. Two `RayCast2D` probes check for ground ahead and walls ahead; the beetle reverses at a ledge, wall, or its exported patrol limit. It ignores the player until a Pounce or Tail Swipe lands, then remembers that player and pursues beyond its patrol limit. During pursuit it waits at walls and ledges instead of trying to cross them. Place its center about 35 pixels above a flat floor; this first version moves at a fixed height rather than following slopes. `walk_speed`, `patrol_half_width`, `chase_speed`, `chase_stop_distance`, `max_health`, and `contact_damage` can be tuned in the Inspector. A Pounce stuns it and makes it harmless briefly; two ordinary Tail Swipes or one Swipe during stun defeat it. Its current polygon artwork is a code-native placeholder.

Tail Swipe cancels Glide but a lateral attack does not change velocity until it actually hits an enemy. A lateral hit then recoils away while retaining 60% of horizontal speed, with a minimum recoil of 180. Hold down as the dominant movement direction to attack below: this preserves horizontal speed, briefly reduces vertical speed to 35%, and launches upward at a minimum speed of 420 when it connects. Lateral and downward attacks use separate 82-pixel convex semicircle hitboxes and separate line indicators; only the matching pair activates. This separation is intentional preparation for different attack animations. The practice dummy is defeated by two ordinary Tail Swipes or one Tail Swipe while Pounce-stunned.

Most developer-only controls are separate from player bindings; the overlay toggle itself can be rebound under **Pause > Controls > Dev Mode**:

| Developer action | Controller | Keyboard |
| --- | --- | --- |
| Toggle developer overlay | Right stick click | F3 |
| Toggle Flight Mode during play | X / Square | F5 |
| Toggle hitbox/hurtbox drawing while dev mode is visible | Left stick click | F4 |
| Reset the current room while developer mode is visible | View / Create | R |
| Next room while developer mode is visible (wraps to first) | Y / Triangle | — |
| Back out of menus | B / Circle | Escape |

The developer menu pauses gameplay while open. Navigate its controls with the D-pad or left stick and select with A / Cross. Its **Flight Mode** checkbox enables direct four-direction movement with no gravity; release the stick or keys to hover instantly. Toggle Flight Mode during play with X / Square or F5, and rebind it under **Pause > Controls > Flight Mode**. Normal jump and Glide behavior return when flight is off; the choice resets when the room reloads.

## Room changes

`RoomManager` is an autoload, so it survives when Godot replaces the current room scene. A `RoomDoor` stores the destination scene and destination spawn position in exported Inspector fields. When the player enters, the manager carries velocity, health, and facing to the new Player instance. Disable **Preserve Momentum** on a door to apply its exported **Entry Velocity** instead. See `ROOM_SYSTEM_REFERENCE.md` for the room-building checklist.
