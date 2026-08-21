--!strict

const FrameData = require(script.Parent.FrameData)
const Reactions = require(script.Parent.Reactions)

const SwingTrail: FrameData.VfxEntry = { Kind = "SwingTrail", Tick = 10, Duration = 12 }

const Launcher: FrameData.FrameData = table.freeze {
    Startup = 10,
    Active = 3,
    Recovery = 25,

    Damage = 8,
    Hitstun = 165,
    Blockstun = 15,
    PostureDamage = 10,

    -- Placeholder. The suspend replaces this in Phase 2; do not tune it for feel.
    KnockbackSpeed = 0,
    KnockbackUpward = 0,
    KnockbackDuration = 1,

    -- A launch extends a combo, a ragdoll ends one.
    Ragdoll = false,

    Range = 2,
    HitboxSize = Vector3.new(4, 6, 4),

    Hitstop = 3,

    IgnoresBlock = false,
    UsableFromBlock = false,

    SuspendTicks = 120,

    ComboWindow = 60,
    JumpLockoutTicks = 28,

    Vfx = { SwingTrail },
    -- Reusing the M1 finisher clip until a launcher is authored.
    AnimationId = "rbxassetid://87995838458656",
    Reaction = "Launch" :: Reactions.ReactionKind,
} :: FrameData.FrameData

const Uptilt: { FrameData.FrameData } = {
    Launcher,
}

return table.freeze(Uptilt)
