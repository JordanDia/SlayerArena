--!strict

const FrameData = require(script.Parent.FrameData)
const Reactions = require(script.Parent.Reactions)
const SoundManifest = require(script.Parent.SoundManifest)
const StretchArm = require(script.Parent.StretchArm)

const STARTUP = 12
const ACTIVE = 180
const HIT_INTERVAL = 4

const Swing: FrameData.SoundEntry = { Kind = "PunchSwing", Tick = 12 }
const Barrage: FrameData.VfxEntry = { Kind = "GatlingArm", Tick = STARTUP + 2, Duration = ACTIVE}

const Gatling: FrameData.FrameData = table.freeze {
    Startup = STARTUP,
    Active = ACTIVE,
    Recovery = 15,

    Damage = 2,
    Hitstun = 55,
    Blockstun = 15,
    PostureDamage = 1,

    KnockbackSpeed = 0,
    KnockbackUpward = 0,
    KnockbackDuration = 0,

    Ragdoll = false,

    Range = 7,
    HitboxSize = Vector3.new(8, 12, 10),
    HitInterval = HIT_INTERVAL,

    Hitstop = 0,

    FreezesInPlace = true,
    LocksMovement = true,
    FacesCamera = true,
    AimsWhileActive = true,

    IgnoresBlock = false,
    UsableFromBlock = false,

    ComboWindow = 0,
    JumpLockoutTicks = 20,

    Vfx = { Barrage },
    Sound = {  },
    AnimationId = "rbxassetid://84262483358352",
    LoopAnimationId = "rbxassetid://87509101185319",
    Reaction = "Heavy" :: Reactions.ReactionKind,
} :: FrameData.FrameData

const Abilities: { FrameData.FrameData } = {
    Gatling,
}

return table.freeze(Abilities)
