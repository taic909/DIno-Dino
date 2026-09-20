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

| Action | Controller | Keyboard |
| --- | --- | --- |
| Move | Left stick or D-pad | A / D |
| Glide Climb | Left stick up or D-pad up | W |
| Glide Dive | Left stick down or D-pad down | S |
| Jump / Glide | Bottom face button (A on Xbox, Cross on PlayStation) | Space |
| Pounce | Left shoulder button (LB on Xbox, L1 on PlayStation) | E or left mouse button |
| Tail Swipe | Unassigned; not implemented yet | Unassigned; not implemented yet |
| Pause | Menu / Options | Escape |

Open **Pause > Controls** to replace keyboard/mouse and controller bindings independently. Changes are saved in Godot's per-user data folder, not in the project files. Use **Restore Defaults** to return to the bindings above.

Tap or hold the first Jump press to control jump height. Release it, then press Jump again while airborne to start a Glide lasting up to 2 seconds; holding the original jump does not activate Glide, and releasing the second press does not cancel it. The Glide timer resets when the player lands. Glide uses conventional flight controls: push the left stick up or press W to climb, and push it down or press S to dive. Pitch is unrestricted, so continued input can rotate through a complete loop. With no pitch input, the dinosaur gradually settles into a shallow descent instead of flying perfectly horizontally. Steeper downward angles accelerate more strongly. Glide inherits existing speed so Pounce and rebound momentum can carry into it. Outside Glide, Pounce uses a fixed launch speed. During Glide, Pounce launch speed is a multiplier of current overall speed, the Glide artwork remains active, and the Glide timer pauses until the short burst ends. Enemies behave like curved bounce surfaces: off-center hits send the dinosaur upward and away, while a centered hit from above sends it straight up. A successful Glide Pounce refills the timer for another chain.

Developer-only controls are separate from player bindings:

| Developer action | Controller | Keyboard |
| --- | --- | --- |
| Toggle developer overlay | — | F3 |
| Reset the current room while developer mode is visible | View / Create | R |
