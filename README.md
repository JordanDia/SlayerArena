# SlayerArena

A parry-based Demon Slayer battlegrounds game for Roblox, built on a server-authoritative
fixed-tick ECS.

Combat is a fighting-game interaction loop with real frame data and honest frame advantage, where
the parry — not the block — is the central defensive read. Breathing styles are picked at spawn and
equipped into skill slots; each style is a set of data tables and animations, not a fork of the
systems.

Battlegrounds means no levels, XP, saves, quests, NPCs, or economy — you drop into an arena with a
style and fight. The ECS underneath is not specific to that, and an RPG built on the same combat
core is planned as a separate fork later.

---

## Architecture

### ECS (Jecs)

State lives in components, behaviour lives in systems, and nothing owns anything it doesn't need to.

A combatant is an entity carrying `Health`, `Posture`, `Stamina`, a `CharacterRef` to its Roblox
`Model`, and whatever temporary state it happens to be in: `ActiveAttack`, `Blockstun`,
`Invulnerable`, `Grabbed`, `Thrown`. Most mechanics are a component appearing, a system reacting,
and the component expiring.

Two conventions do a lot of work:

- **Intents are data, not calls.** Input writes `AttackIntent` / `DodgeIntent` / `BlockHeld`, and
  systems decide whether they're legal. Because an intent is a component with an `ExpiresAt`, an
  input that arrives a few ticks early simply retries until it's accepted. That is the input buffer.
- **NPC behaviour emits the same components player input does.** Training dummies write
  `AttackIntent` and `BlockHeld`, so they exercise exactly the code path a human does. There is no
  parallel "AI attack" route to drift out of sync.

### Scheduler and pipeline

A fixed **60 Hz** tick accumulates against `RunService`, with catch-up capped so a lag spike can't
run twenty ticks at once. Every duration in the game is expressed in ticks, never seconds, so frame
data means the same thing on every machine.

Systems are registered into an ordered `Pipeline`, and **the order is part of the design**:

```
Expiry → DummyBehavior → Block → Dodge → Attack → AttackAnimation
       → HitDetection → HitApplication → GrabRelease
       → HitReactionAnimation → HitstopAnimation → MovementLock
       → KnockbackReplication → NpcKnockback → Posture → StaminaRegen → Reap
```

`Expiry` running first is what lets a held block re-acquire on the exact tick blockstun ends.
`GrabRelease` sitting between `HitApplication` and the knockback systems is what makes a throw
launch on its own tick instead of one late. Each slot is load-bearing, and the pipeline locks after
registration so ordering can't be quietly changed at runtime.

### Client/server split

The server owns all combat state. Clients send intent over **ByteNet** packets and receive VFX and
knockback instructions. They never assert a hit. Movement is the one thing applied client-side, by
necessity: players own their own character's physics, so knockback is replicated as an instruction
and applied by the owner, with a server-side sibling system for NPCs.

---

## Mechanics

### Light attacks

A four-hit M1 string with per-hit frame data covering startup, active, recovery, damage, hitstun,
blockstun, knockback, and a combo window. Hits 1 to 3 are **+2 on block**. The finisher is **-18**,
which is a real punish window rather than a nominal one.

Combo state is a `ComboChain` component carrying the ability and index, so a grab thrown into the
middle of a string can't corrupt it.

### Hitstop

Both parties freeze briefly on contact, with animation tracks paused and resumed. Crucially the
attacker's `ActiveAttack` tracks `PausedTicks`, and every downstream deadline is offset by the
*delta*, so hitting two targets on consecutive ticks doesn't stretch the attack to double length.

### Blocking

A Smash-style shield rather than a stance. `BlockHeld` is a persistent desired-state component
mirroring whether the key is down, not a consume-once intent. That's what makes releasing during
blockstun work: the request retries every tick and fires the moment blockstun clears.

Blocking drains **Posture**, a resource that also regenerates on a delay. Running out breaks the
guard into a full stun. Blocked hits deal chip posture damage, apply blockstun, and push back.

### Spot dodge

2 startup, 14 invulnerable, 12 recovery, at a Posture cost. `Invulnerable` carries a `StartsAt` as
well as an `EndsAt`, so i-frames deliberately don't begin on frame 1 and mashing dodge isn't a
universal answer. Because the invulnerability check sits above the block branch in hit application,
dodge beats grab for free.

### Grabbing

The answer to a turtling opponent. Grab `IgnoresBlock`, and is `UsableFromBlock` so it can be thrown
out of your own shield.

Grab is a genuine hold-and-throw rather than a hit with a different animation. On contact the victim
is welded to the holder's hand with a `Motor6D`, carried through the wind-up, and launched on an
exact tick defined in data (`ReleaseTick`) so the physical throw matches the authored animation
frame for frame. Holding someone means merging two physics assemblies, which brings network
ownership, assembly-root priority, and collision groups into scope. All of it is handled as a single
`Thrown` lifetime that ends when the victim lands, not on a fixed timer.

Getting hit mid-carry breaks the hold and drops the victim without a launch.

### Training dummies

Configurable NPCs used as measuring instruments rather than opponents:

- **Swinging:** attacks on an interval
- **Blocking:** holds guard with an effectively unbreakable Posture pool
- **Punisher:** holds block and fires a grab on the exact tick blockstun clears, blindly. It's a
  pass/fail lamp for frame advantage. If it grabs you, you weren't plus.

---

## Planned

### Combat

The parry triangle is in: M1 loses to parry, parry loses to feint, and the feint is a right-click
during M1 startup. Right-click is one contextual input the server resolves into feint, parry, or
block. Posture fills toward a guard break rather than draining, so holding block is pressure rather
than safety, and the critical is always available but only unblockable in the window after a parry.

Still open:

- **Ragdoll** on knockback, with a getup window (`InvulnerableKind` already reserves `"Getup"`).
- **Juggles.** `Uptilt`/`Suspend`/`GroundPin` are implemented but no longer routed to, pending a
  decision on whether launches belong in a parry-first game.

### Breathing styles
- **Styles as data.** `Abilities` maps an id to a list of frame data and every system reads the
  ability from data rather than naming M1, so a style is new data plus animations.
- **Per-entity slot resolution.** `SkillSlots` is the seam: it resolves a slot number to an
  `AbilityId`, and is currently an empty placeholder awaiting the equipped-style resolver.

### Match flow
- **Round lifecycle** — spawn, fight, reset — plus scoring and a results screen.

---

## Stack

Luau (strict mode), [Jecs](https://github.com/Ukendio/jecs),
[ByteNet](https://github.com/ffrostflame/ByteNet), Rojo, Wally, Selene
