--!strict

const FrameData = require(script.Parent.FrameData)
const Reactions = require(script.Parent.Reactions)
const SoundManifest = require(script.Parent.SoundManifest)
const StretchArm = require(script.Parent.StretchArm)

const Swing: FrameData.SoundEntry = { Kind = "PunchSwing", Tick = 12 }

const STARTUP = 14
const ACTIVE = StretchArm.Pistol.ExtendTicks
const START_RANGE = StretchArm.Pistol.StartRange
const MAX_RANGE = StretchArm.Pistol.MaxRange

const ARM_DELAY = 10

const Arm: FrameData.VfxEntry = { Kind = "PistolArm", Tick = STARTUP + ARM_DELAY, Duration = ACTIVE }

const GomuPistolCharge: FrameData.SoundEntry = { Kind = "GomuPistolCharge", Tick = 0 }

const Pistol: FrameData.FrameData = table.freeze {
    Startup = STARTUP,
    Active = ACTIVE,
    Recovery = 15,

    Damage = 14,
    Hitstun = 55,
    Blockstun = 15,
    PostureDamage = 12,

    KnockbackSpeed = 45,
    KnockbackUpward = 8,
    KnockbackDuration = 10,

    Ragdoll = false,

    Range = START_RANGE,
    HitboxSize = Vector3.new(5, 6, 5),

    HitboxSpeed = (MAX_RANGE - START_RANGE) / ACTIVE,
    HitboxMaxRange = MAX_RANGE,

    Hitstop = 4,

    FreezesInPlace = true,
    LocksMovement = true,
    FacesCamera = true,

    Chargeable = true,
    MaxChargeTicks = 120,

    IgnoresBlock = false,
    UsableFromBlock = false,

    ComboWindow = 0,
    JumpLockoutTicks = 20,

    Vfx = { Arm },
    Sound = { Swing, GomuPistolCharge },
    AnimationId = "rbxassetid://118301307655175",
    Reaction = "Heavy" :: Reactions.ReactionKind,
} :: FrameData.FrameData

const Abilities: { FrameData.FrameData } = {
    Pistol,
}

return table.freeze(Abilities)
