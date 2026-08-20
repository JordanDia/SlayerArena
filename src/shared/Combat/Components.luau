--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Jecs = require(ReplicatedStorage.Packages.Jecs)
const Abilities = require(ReplicatedStorage.Shared.Combat.Data.Abilities)
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
    Direction: Vector3,
}

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
    PausedTicks: number,
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

export type Ragdolled = {}

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

    -- Attack stuff
    ActiveAttack = World:component() :: Jecs.Id<ActiveAttack>,
    AttackIntent = World:component() :: Jecs.Id<AttackIntent>,
    Hitstop = World:component() :: Jecs.Id<Hitstop>,

    -- Blocking
    Blocking = World:component() :: Jecs.Id<Blocking>,
    BlockHeld = World:component() :: Jecs.Id<BlockHeld>,
    Blockstun = World:component() :: Jecs.Id<Blockstun>,

    -- Dodging
    DodgeIntent = World:component() :: Jecs.Id<DodgeIntent>,

    -- Grabbing
    Grabbed = World:component() :: Jecs.Id<Grabbed>,
    Holding = World:component() :: Jecs.Id<Holding>,

    AnimationTracks = World:component() :: Jecs.Id<{ [string]: AnimationTrack }>,

    -- Dummy stuff
    Dummy = World:component() :: Jecs.Id<Dummy>,
    DummyBehavior = World:component() :: Jecs.Id<DummyBehavior>,

    Thrown = World:component() :: Jecs.Id<Thrown>,
    Ragdolled = World:component() :: Jecs.Id<Ragdolled>,
    
    -- Tags
    Dead = World:entity()
}

return table.freeze(Components)
