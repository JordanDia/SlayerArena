--!strict

const FrameData = require(script.Parent.FrameData)
const Reactions = require(script.Parent.Reactions)

-- currently unused
const _SwingTrail: FrameData.VfxEntry = { Kind = "SwingTrail", Tick = 6, Duration = 10}
const _SwingTrailFinisher: FrameData.VfxEntry = { Kind = "SwingTrail", Tick = 9, Duration = 10}

const Swing: FrameData.SoundEntry = { Kind = "PunchSwing", Tick = 6 }

const FirstHit: FrameData.FrameData = table.freeze {
    Startup = 6,
    Active = 3,
    Recovery = 7,

    Damage = 5,
    Hitstun = 45,
    Blockstun = 12,
    PostureDamage = 5,

    KnockbackSpeed = 5,
    KnockbackUpward = 0,
    KnockbackDuration = 5,

    Ragdoll = false,

    Range = 3,
    HitboxSize = Vector3.new(4, 6, 5),

    Hitstop = 2,

    IgnoresBlock = false,
    UsableFromBlock = false,
    
    ComboWindow = 60,
    JumpLockoutTicks = 10,
    
    Vfx = {},
    Sound = { Swing },

    AnimationId = "rbxassetid://101027333825650",
    Reaction = "Light" :: Reactions.ReactionKind,
}

const SecondHit: FrameData.FrameData = table.freeze {
    Startup = 6,
    Active = 3,
    Recovery = 7,

    Damage = 5,
    Hitstun = 45,
    Blockstun = 12,
    PostureDamage = 5,

    KnockbackSpeed = 5,
    KnockbackUpward = 0,
    KnockbackDuration = 5,

    Ragdoll = false,

    Range = 3,
    HitboxSize = Vector3.new(4, 6, 5),

    Hitstop = 2,

    IgnoresBlock = false,
    UsableFromBlock = false,
    
    ComboWindow = 60,
    JumpLockoutTicks = 10,

    Vfx = {  },
    Sound = { Swing },
    
    AnimationId = "rbxassetid://97544456513431",
    Reaction = "Light" :: Reactions.ReactionKind,
}

const ThirdHit: FrameData.FrameData = table.freeze {
    Startup = 6,
    Active = 3,
    Recovery = 7,

    Damage = 5,
    Hitstun = 45,
    Blockstun = 12,
    PostureDamage = 5,

    KnockbackSpeed = 5,
    KnockbackUpward = 0,
    KnockbackDuration = 5,

    Ragdoll = false,

    Range = 3,
    HitboxSize = Vector3.new(4, 6, 5),

    Hitstop = 2,
    
    IgnoresBlock = false,
    UsableFromBlock = false,

    ComboWindow = 60,
    JumpLockoutTicks = 10,

    Vfx = {  },
    Sound = { Swing },

    AnimationId = "rbxassetid://126850736653474",
    Reaction = "Light" :: Reactions.ReactionKind,
}

const FourthHit: FrameData.FrameData = table.freeze {
    Startup = 9,
    Active = 3,
    Recovery = 30,

    Damage = 10,
    Hitstun = 90,
    Blockstun = 15,
    PostureDamage = 10,

    KnockbackSpeed = 65,
    KnockbackUpward = 10,
    KnockbackDuration = 1,

    Ragdoll = true,

    Range = 3,
    HitboxSize = Vector3.new(4, 6, 5),

    Hitstop = 2,

    IgnoresBlock = false,
    UsableFromBlock = false,

    ComboWindow = 60,
    JumpLockoutTicks = 5,

    Vfx = {  },
    Sound = { Swing },
    
    AnimationId = "rbxassetid://87995838458656",
    Reaction = "Light" :: Reactions.ReactionKind,
}

const M1: { FrameData.FrameData } = {
    FirstHit,
    SecondHit,
    ThirdHit,
    FourthHit,
}

return table.freeze(M1)