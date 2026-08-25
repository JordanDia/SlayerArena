# Basic Slayer — 7 Day Plan

Fork of CombatTesting (GPO-style). Target: parry-based Demon Slayer battlegrounds.
Tick rate 60Hz, fixed-step ECS (Jecs). All windows below are in TICKS.

---

## Core Combat Design

### The triangle (as designed by Jordan, Day 0)
```
M1        -> beaten by Parry
Parry     -> beaten by Feint
Feint     -> beaten by M1 pressure (feint costs stamina + lock)
```
Critical (M3) sits outside the triangle as the parry PAYOFF, not a fourth option.

### Input model: RMB is ONE contextual button
| Context when RMB pressed | Result |
|---|---|
| You have an ActiveAttack still in Startup | FEINT - cancel the attack |
| Anything else | PARRY window opens (10 ticks) |
| RMB still held after the parry window expires | falls through to BLOCK |
| RMB still held after a FEINT | falls through to PARRY, then BLOCK |

The feint -> block fallthrough is required: the player never presses RMB twice.
One hold produces feint, then parry, then block, in that order.

### Critical (M3 / MouseButton3)
- Only usable inside a short CritWindow opened by a SUCCESSFUL parry.
- Unblockable, cannot itself be parried, high damage, unique animation + cam.
- This is the entire reward for parrying. Miss the window, lose the payoff.

### Posture (INVERT current behaviour)
- `Posture.Current` fills 0 -> Max. Break at Max, not at 0.
- Sources of posture gain: blocked hit (full), parried-by-you (attacker gains a lot),
  whiffed parry (small self-gain).
- Decay: none for `RegenDelay` ticks after last gain, then decay per tick.
  Flat decay rate to start; tune on Day 7.
- At Max -> `Stunned{Reaction="GuardBreak"}`, a free punish window for the attacker.
- Posture NO LONGER pays for dash/dodge. That moves to `Stamina`.

### Block (RMB held, after the parry window lapses)
- Chip damage (~20% of Damage), heavy posture gain, no stun on you, cannot be
  broken by M1 alone within one combo string.
- Chip + posture gain is the pressure; there are no unblockable normals.

### Parry (RMB press)
- Active window: 10 ticks. Whiff recovery: 15 ticks (`ActionLock`, cannot block/attack).
- On success: attacker -> `Stunned{Reaction="Parried"}` for ~40 ticks, attacker gains
  big posture, you gain zero posture, hitstop freeze on both, screen shake + spark VFX.
- Consecutive parries in one string tighten the window (10 -> 8 -> 7) so holding RMB
  forever is not a free parry.
- On success: opens the CritWindow for M3.

### Feint (RMB during your own M1 startup)
- Cancels an attack during Startup only. Costs stamina, applies a short ActionLock.
- Purpose: bait the opponent's parry, then punish its recovery.
- If RMB stays held, flows straight into parry/block. No second press.

### Critical
- Trigger: press M3 inside the CritWindow granted by a successful parry.
- Effect: unblockable, unparryable, ~2.5x damage, unique animation + camera.

### Files to touch on Day 1
- `src/shared/Combat/Data/Block.luau`      -> split into Block.luau + Parry.luau
- `src/shared/Combat/Systems/PostureSystem.luau` -> invert fill/decay
- `src/shared/Combat/Systems/BlockSystem.luau`   -> split tap vs hold
- `src/shared/Combat/Systems/HitApplicationSystem.luau:27-113` -> parry/block/crit branch
- `src/shared/Combat/Components.luau`      -> add Parrying, ParryRecovery, CritWindow
- `src/shared/Combat/Data/FrameData.luau`  -> add Feintable, ChipMultiplier
- `src/client/Combat/CombatInputController.luau:185-191` -> tap vs hold on F

---

## Content Scope (locked — do not expand this week)

### Breathing Styles: 3 at launch
| Style | Identity | 4 skills (Z X C V) |
|---|---|---|
| Water | Balanced starter, flowing combos | Water Surface Slash / Water Wheel / Flowing Dance / Constant Flux |
| Thunder | Burst mobility, one huge commit | Thunderclap and Flash (dash-through) / Fivefold / Rice Spirit / Heat Lightning |
| Flame | Slow, unblockable-heavy, high damage | Unknowing Fire / Rising Scorching Sun / Blooming Flame Undulation / Flame Tiger |

Design rule: each style gets one gap-closer, one fast parry-punish, one crowd/space
control, one big commit.

Stretch (Day 7+ only, cut without guilt): Wind, Sound, Beast, Demon Blood Art path.

### Weapons: Nichirin blade only
One weapon type. Variants are STAT skins (colour + damage/speed tuning), not new
movesets. Rarity tiers: Common / Rare / Slayer / Hashira.

### Battlegrounds shape (NOT an RPG - decided Day 0)
- Free-for-all arena. Spawn -> fight -> die -> respawn. No levels, no XP, no saves,
  no quests, no NPCs, no economy. Cut all of it.
- Style select on spawn: pick a breathing style, get its 4 skills. That is the
  entire "progression" surface.
- Session-only stats: kills / deaths / best combo on a leaderboard.
- Everyone has identical Health/Posture/Stamina. Balance lives in frame data only.

---

## Day Schedule

**Day 1 - Combat core.** Posture inversion, Block/Parry split, Feint, Criticals,
M3 critical, tuned against the training dummies. No new content.
Success test: parry-loop a dummy, get guard broken, land a crit.

**Day 2 - Breathing style framework + Water & Thunder.**
`Data/Styles/` folder, fill in the `SkillSlots.luau` resolver, equip/swap, 8 abilities
as FrameData. Placeholder VFX only.

**Day 3 - Flame + match flow.** Third style, style select screen, spawn/respawn
system, session kill/death tracking, leaderboard.

**Day 4 - UI.** Health/Posture/Stamina bars, skill hotbar w/ cooldown radials,
parry flash, combo counter, killfeed, style selector. Fusion is already in Packages.

**Day 5 - Map.** ONE arena. Blockout quality is fine; art pass is Day 6/7.
Spawn points, kill floor, boundaries.

**Day 6 - VFX + SFX + animations.** Real breathing-style effects (this is what sells a
Demon Slayer game), parry spark, guard break, crit cam, hit sounds, music.

**Day 7 - Polish + balance.** Playtest with real people, tune frame data, fix the
top 10 bugs, add a parry tutorial prompt, ship.

Non-negotiable: if a day runs over, cut CONTENT (a style, a skill), never cut Day 1
combat feel or Day 6 VFX. Those two are the entire game.

---

## Tuning constants (forgiving / VV-style, decided Day 0)
- Parry active window: 10 ticks
- Parry whiff recovery: 15 ticks
- Consecutive-parry tightening: 10 -> 8 -> 7 (floor)
- Parried stun on attacker: 40 ticks
- CritWindow after a successful parry: 45 ticks
- Feint stamina cost: 15, feint ActionLock: 15 ticks
- Posture Max: 50 (existing), guard break when Current reaches Max
- Posture decay delay: 90 ticks, then 0.5/tick

---

## Working mode
Jordan writes all the code. Claude acts as a tutor: brief explanation of WHY, then
the exact snippet and which file it goes in. One step at a time, verify before
moving on.
