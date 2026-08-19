--!strict

const FrameData = require(script.Parent.FrameData)

const NormalGrab = table.freeze {

    Startup = 18,
    Active = 3,
    Recovery = 39,

    ReleaseTick = 40,

    Damage = 14,
    Hitstun = 60,
    Blockstun = 0,
    PostureDamage = 0,

    KnockbackSpeed = 40,
    KnockbackUpward = 35,
    KnockbackDuration = 15,

    Range = 4,
    Radius = 2.5,

    Hitstop = 2,

    IgnoresBlock = true,
    UsableFromBlock = true,
    
    ComboWindow = 60,

    AnimationId = "rbxassetid://137719651597620",
    Reaction = "Grab",

} :: FrameData.FrameData

const Grab: { FrameData.FrameData } = {
    NormalGrab
}

return table.freeze(Grab)