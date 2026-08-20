--!strict

const FrameData = require(script.Parent.FrameData)
const Reactions = require(script.Parent.Reactions)

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

    Range = 6,
    Radius = 3,

    Hitstop = 2,

    IgnoresBlock = false,
    UsableFromBlock = false,
    
    ComboWindow = 60,

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

    Range = 6,
    Radius = 3,

    Hitstop = 2,

    IgnoresBlock = false,
    UsableFromBlock = false,
    
    ComboWindow = 60,

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

    Range = 6,
    Radius = 3,

    Hitstop = 2,
    
    IgnoresBlock = false,
    UsableFromBlock = false,

    ComboWindow = 60,

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

    KnockbackSpeed = 60,
    KnockbackUpward = 30,
    KnockbackDuration = 20,

    Ragdoll = true,

    Range = 6,
    Radius = 3,

    Hitstop = 2,

    IgnoresBlock = false,
    UsableFromBlock = false,

    ComboWindow = 60,

    AnimationId = "rbxassetid://87995838458656",
    Reaction = "Light" :: Reactions.ReactionKind,
} :: FrameData.FrameData

const M1: { FrameData.FrameData } = {
    FirstHit,
    SecondHit,
    ThirdHit,
    FourthHit,
}

return table.freeze(M1)