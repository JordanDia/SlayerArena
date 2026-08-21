--!strict

const Reactions = require(script.Parent.Reactions)
const VfxManifest = require(script.Parent.VfxManifest)

export type VfxEntry = {
    read Kind: VfxManifest.VfxKind,
    read Tick: number,
    read Duration: number?
}

-- Timing is in ticks, 60 Hz
export type FrameData = {
    read Startup: number,
    read Active: number,
    read Recovery: number,

    read Damage: number,
    read Hitstun: number,
    read Blockstun: number,
    read PostureDamage: number,

    read KnockbackSpeed: number,
    read KnockbackUpward: number,
    read KnockbackDuration: number,

    read Ragdoll: boolean,

    read Range: number,
    read HitboxSize: Vector3,

    read Hitstop: number,

    read IgnoresBlock: boolean,
    read UsableFromBlock: boolean,

    read ComboWindow: number,

    read AnimationId: string,
    read Reaction: Reactions.ReactionKind,

    read Vfx: { VfxEntry }?,

    -- optional, used for grabbing
    read ReleaseTick: number?
}

return {}