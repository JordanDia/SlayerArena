--!strict

const FrameData = require(script.Parent.FrameData)
const Reactions = require(script.Parent.Reactions)

const Swing: FrameData.SoundEntry = { Kind = "PunchSwing", Tick = 18 }

const Slash1: FrameData.FrameData = table.freeze {
    Startup = 20,
    Active = 13,
    Recovery = 8,

    Damage = 5,
    Hitstun = 45,
    Blockstun = 12,
    PostureDamage = 7,

    KnockbackSpeed = 0,
    KnockbackUpward = 0,
    KnockbackDuration = 0,

    Ragdoll = false,

    Range = 4,
    HitboxSize = Vector3.new(5, 6, 6),

    Hitstop = 4,

    IgnoresBlock = false,
    UsableFromBlock = false,

    ComboWindow = 60,
    JumpLockoutTicks = 10,

    Vfx = {},
    Sound = { Swing },

    AnimationId = "rbxassetid://112995097940187",
    Reaction = "Light" :: Reactions.ReactionKind,
}

const Slash2: FrameData.FrameData = table.freeze {
    Startup = 20,
    Active = 13,
    Recovery = 8,

    Damage = 5,
    Hitstun = 45,
    Blockstun = 12,
    PostureDamage = 7,

    KnockbackSpeed = 0,
    KnockbackUpward = 0,
    KnockbackDuration = 0,

    Ragdoll = false,

    Range = 4,
    HitboxSize = Vector3.new(5, 6, 6),

    Hitstop = 4,

    IgnoresBlock = false,
    UsableFromBlock = false,

    ComboWindow = 60,
    JumpLockoutTicks = 10,

    Vfx = {},
    Sound = { Swing },

    AnimationId = "rbxassetid://95473188452901",
    Reaction = "Light" :: Reactions.ReactionKind,
}

const M1: { FrameData.FrameData } = {
    Slash1,
    Slash2,
}

return table.freeze(M1)
