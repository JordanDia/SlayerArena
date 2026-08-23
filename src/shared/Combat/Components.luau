--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Jecs = require(ReplicatedStorage.Packages.Jecs)
const Abilities = require(ReplicatedStorage.Shared.Combat.Data.Abilities)
const CooldownDurations = require(ReplicatedStorage.Shared.Combat.Data.CooldownDurations)
const Dash = require(ReplicatedStorage.Shared.Combat.Data.Dash)
const DoubleJump = require(ReplicatedStorage.Shared.Combat.Data.DoubleJump)
const Reactions = require(ReplicatedStorage.Shared.Combat.Data.Reactions)
const World = require("./World")

export type CharacterRef = {
    Model: Model,
    Humanoid: Humanoid,
    Root: BasePart,
}

export type Health = {
    Current: number,
    Max: number,
}

export type Posture = {
    Current: number,
    Max: number,
    LastDamagedTick: number,
}

export type Stamina = {
    Current: number,
    Max: number,
    RegenPerTick: number,
}

export type Stunned = {
    StartedAt: number,
    EndsAt: number,
    Reaction: Reactions.ReactionKind,
    Source: World.Entity?,
}

export type ActionLock = {
    EndsAt: number,
    Mask: number,
}

export type InvulnerableKind = "Dodge" | "Getup" |  "Spawn"
export type Invulnerable = {
    StartsAt: number,
    EndsAt: number,
    Kind: InvulnerableKind,
}

export type BlockHeld = {
    Wants: boolean
}

export type Blocking = {
    Since: number,
}

export type Blockstun = {
    EndsAt: number,
}

export type Dashing = {
    EndsAt: number,
    -- World space, resolved once at dash start. Consumers must NOT run this through
    -- VectorToWorldSpace: it used to be character-local, and re-resolving it per frame
    -- also made dashes curve as AutoRotate turned the character mid-dash.
    Direction: Vector3,
    Kind: Dash.DashKind,
}

export type DoubleJumpIntent = {
    Kind: DoubleJump.DoubleJumpKind,
    ExpiresAt: number,
    -- World space, already flattened. Zero means no directional input.
    Direction: Vector3,
}

export type DoubleJumping = {
    EndsAt: number,
    Kind: DoubleJump.DoubleJumpKind,
}

export type DashIntent = {
    Kind: Dash.DashKind,
    ExpiresAt: number,
    -- World space and already flattened. Zero means "no input", and the dash falls
    -- back to the character-relative vector for Kind.
    Direction: Vector3,
}

export type Cooldowns = { [CooldownDurations.CooldownId]: number }

export type ComboChain = {
    Index: number,
    ExpiresAt: number,
    Ability: Abilities.AbilityId
}

export type ComboCounter = {
    Hits: number,
    DecaysAt: number,
    Target: World.Entity
}

export type Knockback = {
    Velocity: Vector3,
    StartedAt: number,
    EndsAt: number
}

export type AirJumps = {
    Used: number,
    Max: number
}

export type JumpLockout = {
    EndsAt: number
}

export type DodgeIntent = {
    ExpiresAt: number,
}

export type AttackIntent = {
    Ability: Abilities.AbilityId,
    ExpiresAt: number
}

export type ActiveAttack = {
    Ability: Abilities.AbilityId,
    HitIndex: number,
    StartedAt: number,
    HasHit: { [World.Entity]: boolean },
    FiredVfx: { [number]: boolean },
    FiredRecoil: boolean,
    FiredSounds: { [number]: boolean },
    PausedTicks: number,
    HitboxOrigin: CFrame?,
}

export type Hitstop = {
    EndsAt: number,
    Frozen: { [AnimationTrack]: number }?
}

export type Grabbed = {
    Holder: World.Entity,
    Ability: Abilities.AbilityId,
    HitIndex: number,
    ReleasesAt: number,
}

export type Holding = {
    Victim: World.Entity,
}

export type UptiltHeld = {
    Wants: boolean,
}

export type SkillHeld = {
    Wants: boolean,
}

export type FacingLocked = {
    StartedAt: number,
}

export type FrozenInPlace = {
    StartedAt: number,
}

export type Charging = {
    StartedAt: number,
    Frozen: { [AnimationTrack]: number }?,
}



export type Dummy = {
    Kind: string,
    Spawn: BasePart,
    Indicator: BasePart
}

export type DummyPolicy = "Swinging" | "Punisher" | "Grabbing"
export type DummyBehavior = {
    Policy: DummyPolicy,
    Interval: number,
    ArmedUntil: number,
    NextActionAt: number,
}

export type Thrown = {
    EndsAt: number,
    MaxEndsAt: number,
}

export type Suspended = {
    StartedAt: number,
    EndsAt: number,
    RiseEndsAt: number,
    Origin: Vector3,
    Goal: Vector3,
    Holder: World.Entity,
}

export type Suspending = {
    StartedAt: number,
    EndsAt: number,
    RiseEndsAt: number,
    Origin: Vector3,
    Goal: Vector3,
    Victim: World.Entity,
}

--[[
    Two components rather than one because the pin has two phases with different
    deadlines: GroundPinPending is waiting for the body to land and expires if it
    never does, GroundPinned is the hold itself and only starts counting once it
    has. Splitting them also lets the AlignPosition live in added/removed hooks,
    which a single component that changes meaning halfway through could not.
]]
export type GroundPinPending = {
    PinTicks: number,
    EndsAt: number,
}

export type GroundPinned = {
    EndsAt: number,
    Position: Vector3,
}

export type Ragdolled = {
    Facing: Vector3,
}

export type Sprinting = {}

const Components = {
    CharacterRef = World:component() :: Jecs.Id<CharacterRef>,
    PlayerRef = World:component() :: Jecs.Id<Player>,

    -- Resources
    Health = World:component() :: Jecs.Id<Health>,
    Posture = World:component() :: Jecs.Id<Posture>,
    Stamina = World:component() :: Jecs.Id<Stamina>,

    -- Temporary States
    Stunned = World:component() :: Jecs.Id<Stunned>,
    ActionLock = World:component() :: Jecs.Id<ActionLock>,
    Invulnerable = World:component() :: Jecs.Id<Invulnerable>,
    Dashing = World:component() :: Jecs.Id<Dashing>,

    -- GPO like combat system stuff
    ComboChain = World:component() :: Jecs.Id<ComboChain>,
    ComboCounter = World:component() :: Jecs.Id<ComboCounter>,
    Knockback = World:component() :: Jecs.Id<Knockback>,

    -- Movement
    AirJumps = World:component() :: Jecs.Id<AirJumps>,
    JumpLockout = World:component() :: Jecs.Id<JumpLockout>,

    Cooldowns = World:component() :: Jecs.Id<Cooldowns>,

    -- Attack stuff
    ActiveAttack = World:component() :: Jecs.Id<ActiveAttack>,
    AttackIntent = World:component() :: Jecs.Id<AttackIntent>,
    Hitstop = World:component() :: Jecs.Id<Hitstop>,
    UptiltHeld = World:component() :: Jecs.Id<UptiltHeld>,
    SkillHeld = World:component() :: Jecs.Id<SkillHeld>,
    Charging = World:component() :: Jecs.Id<Charging>,
    FrozenInPlace = World:component() :: Jecs.Id<FrozenInPlace>,
    FacingLocked = World:component() :: Jecs.Id<FacingLocked>,

    -- Blocking
    Blocking = World:component() :: Jecs.Id<Blocking>,
    BlockHeld = World:component() :: Jecs.Id<BlockHeld>,
    Blockstun = World:component() :: Jecs.Id<Blockstun>,

    -- Dodging
    DodgeIntent = World:component() :: Jecs.Id<DodgeIntent>,

    -- Dashing
    DashIntent = World:component() :: Jecs.Id<DashIntent>,

    -- Double jump
    DoubleJumpIntent = World:component() :: Jecs.Id<DoubleJumpIntent>,
    DoubleJumping = World:component() :: Jecs.Id<DoubleJumping>,

    -- Grabbing
    Grabbed = World:component() :: Jecs.Id<Grabbed>,
    Holding = World:component() :: Jecs.Id<Holding>,

    AnimationTracks = World:component() :: Jecs.Id<{ [string]: AnimationTrack }>,

    -- Dummy stuff
    Dummy = World:component() :: Jecs.Id<Dummy>,
    DummyBehavior = World:component() :: Jecs.Id<DummyBehavior>,

    Thrown = World:component() :: Jecs.Id<Thrown>,
    Ragdolled = World:component() :: Jecs.Id<Ragdolled>,
    Suspended = World:component() :: Jecs.Id<Suspended>,
    Suspending = World:component() :: Jecs.Id<Suspending>,
    GroundPinPending = World:component() :: Jecs.Id<GroundPinPending>,
    GroundPinned = World:component() :: Jecs.Id<GroundPinned>,

    Sprinting = World:component() :: Jecs.Id<Sprinting>,
    
    -- Tags
    Dead = World:entity()
}

return table.freeze(Components)
