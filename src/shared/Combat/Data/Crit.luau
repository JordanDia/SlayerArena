--!strict

const FrameData = require(script.Parent.FrameData)
const Reactions = require(script.Parent.Reactions)


const Normal: FrameData.FrameData = table.freeze {
    Startup = 20,
    Active = 6,
    Recovery = 24,

    Damage = 12,
    Hitstun = 70,
    Blockstun = 20,
    PostureDamage = 20,

    KnockbackSpeed = 0,
    KnockbackUpward = 0,
    KnockbackDuration = 0,

    
    Feintable = false,

    Ragdoll = false,

    Range = 4,
    HitboxSize = Vector3.new(5, 6, 6),

    Hitstop = 8,

    IgnoresBlock = false,
    UsableFromBlock = false,

    ComboWindow = 60,
    JumpLockoutTicks = 10,

    Vfx = {},
    Sound = {},

    AnimationId = "rbxassetid://70479009803903",
    Reaction = "Heavy" :: Reactions.ReactionKind,
}


const Empowered: FrameData.FrameData = table.freeze {
    Startup = 20,
    Active = 6,
    Recovery = 24,

    Damage = 22,
    Hitstun = 70,
    Blockstun = 20,
    PostureDamage = 20,

    KnockbackSpeed = 0,
    KnockbackUpward = 0,
    KnockbackDuration = 0,

    Feintable = false,

    Ragdoll = false,

    Range = 4,
    HitboxSize = Vector3.new(5, 6, 6),

    Hitstop = 8,

    IgnoresBlock = true,
    UsableFromBlock = false,

    ComboWindow = 60,
    JumpLockoutTicks = 10,

    Vfx = {},
    Sound = {},

    AnimationId = "rbxassetid://70479009803903",
    Reaction = "Heavy" :: Reactions.ReactionKind,
}

return table.freeze {
    Normal = table.freeze { Normal } :: { FrameData.FrameData },
    Empowered = table.freeze { Empowered } :: { FrameData.FrameData },
}
