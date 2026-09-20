# Fossilheart Learning Lab

A learn-by-building Godot project for a dinosaur action-platformer with deliberate, responsive combat and exploration.

Before planning or editing the game, read [Project Fossilheart: Source of Truth](GAME_REFERENCE.md). It contains the current creative direction, technical decisions, prototype scope, and development plan.

Development helpers are documented in [Dev Mode Reference](DEV_MODE_REFERENCE.md).

## How we work

Codex implements the game systems and pauses for occasional, focused check-ins. Each check-in explains only the most useful new ideas, and the reusable syntax is added to [Godot Code Library](GODOT_CODE_LIBRARY.md).

Skills can still move through four stages when you want to practice one:

1. **Learn** - Codex provides the exact code, where to put it, and an explanation of every new part.
2. **Repeat** - you type the provided code again in a new situation and predict what it will do.
3. **Prove** - you adapt provided code to a small variation, with exact code available if you get stuck.
4. **Unlocked** - Codex may use that skill to flesh out production content, while explaining any new ideas.

Unlocking is based on understanding, not perfect memory or typing speed. Bugs count as useful evidence when you can explain and fix them.

Every lesson will include:

- the exact file and node to use;
- complete code for every step;
- where each code block belongs;
- what should happen after each test;
- a complete finished script for comparison.

## Roadmap

| Skill | Repetitions to unlock | Status |
| --- | ---: | --- |
| Horizontal movement | 2 | Learning (0/2) |
| Jumping and gravity | 2 | Learning (0/2) |
| Dash and cooldowns | 2 | Locked |
| Animation state | 2 | Locked |
| Hitboxes and hurtboxes | 2 | Locked |
| Basic enemy behavior | 3 | Locked |
| Health and UI | 2 | Locked |
| Room transitions | 2 | Locked |
| Checkpoints and saving | 2 | Locked |
| Boss patterns | 2 phases | Locked |

## First playable milestone

- A dinosaur that runs, jumps, falls, and attacks
- One compact exploration room
- One enemy and a health system
- One doorway to a second room
- One collectible movement ability

Start with [Lesson 01](LESSON_01.md). The placeholder art is temporary on purpose; movement feel comes first.
