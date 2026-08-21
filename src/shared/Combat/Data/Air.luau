--!strict

const FrameData = require(script.Parent.FrameData)
const Reactions = require(script.Parent.Reactions)

const SwingTrail: FrameData.VfxEntry = { Kind = "SwingTrail", Tick = 8, Duration = 10 }
const SlamTrail: FrameData.VfxEntry = { Kind = "SwingTrail", Tick = 10, Duration = 12 }

--[[
    The air string is deliberately two hits, not four. It is one array rather than two
    abilities so ComboChain sequences it for free: the first press finds no matching
    chain and starts at 1, the second resolves to 2. A third press cannot wrap back to 1
    because the slam removes Suspending, which is what routes M1 here in the first place.
]]

const AirSlash: FrameData.FrameData = table.freeze {
    Startup = 8,
    Active = 3,
    Recovery = 12,

    Damage = 6,
    Hitstun = 60,
    Blockstun = 10,
    PostureDamage = 5,

    -- Knockback is skipped entirely against a suspended target, so these never apply
    -- during a juggle. They exist for the case where the air string hits someone else.
    KnockbackSpeed = 5,
    KnockbackUpward = 0,
    KnockbackDuration = 5,

    Ragdoll = false,

    Range = 2,
    HitboxSize = Vector3.new(4, 6, 4),

    Hitstop = 2,

    IgnoresBlock = false,
    UsableFromBlock = false,

    ComboWindow = 60,
    JumpLockoutTicks = 10,

    Vfx = { SwingTrail },
    AnimationId = "rbxassetid://101027333825650",
    Reaction = "Light" :: Reactions.ReactionKind,
} :: FrameData.FrameData

const DownSlam: FrameData.FrameData = table.freeze {
    Startup = 10,
    Active = 3,
    Recovery = 20,

    Damage = 15,
    Hitstun = 90,
    Blockstun = 15,
    PostureDamage = 15,

    -- Negative Upward with forward Speed is the diagonal spike. The victim only starts
    -- travelling once Hitstop clears, which is the beat between the connect and the drop.
    -- Forward distance is Speed times time-to-ground, and time-to-ground is fixed by
    -- Upward and the launch height. So distance scales with Speed alone: 110 landed them
    -- ~30 studs out, 220 lands them ~61. Softening Upward would also buy distance, but by
    -- making them hang, which is the opposite of what a slam should read as.
    KnockbackSpeed = 220,
    KnockbackUpward = -45,
    KnockbackDuration = 8,

    Ragdoll = true,

    Range = 2.5,
    HitboxSize = Vector3.new(4, 6, 4),

    -- Long on purpose: this is the "soon after the hit lands" pause before they are spiked.
    Hitstop = 8,

    IgnoresBlock = false,
    UsableFromBlock = false,

    ComboWindow = 60,
    JumpLockoutTicks = 20,

    EndsSuspend = true,
    PinTicks = 60,

    Vfx = { SlamTrail },
    AnimationId = "rbxassetid://87995838458656",
    Reaction = "Heavy" :: Reactions.ReactionKind,
} :: FrameData.FrameData

const Air: { FrameData.FrameData } = {
    AirSlash,
    DownSlam,
}

return table.freeze(Air)
