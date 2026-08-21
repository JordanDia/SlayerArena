--!strict

const FrameData = require(script.Parent.FrameData)
const Reactions = require(script.Parent.Reactions)

const NormalGrab: FrameData.FrameData = table.freeze {

    Startup = 18,
    Active = 3,
    Recovery = 39,

    ReleaseTick = 40,

    Damage = 14,
    Hitstun = 60,
    Blockstun = 0,
    PostureDamage = 0,

    KnockbackSpeed = 65,
    KnockbackUpward = 15,
    KnockbackDuration = 15,

    Ragdoll = true,

    Range = 2,
    HitboxSize = Vector3.new(4, 6, 4),

    Hitstop = 2,

    IgnoresBlock = true,
    UsableFromBlock = true,
    
    ComboWindow = 60,

    AnimationId = "rbxassetid://137719651597620",
    Reaction = "Grab" :: Reactions.ReactionKind,

}

const Grab: { FrameData.FrameData } = {
    NormalGrab
}

return table.freeze(Grab)