--!strict

const Reactions = require(script.Parent.Reactions)

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

    read Range: number,
    read Radius: number,

    read Hitstop: number,

    read IgnoresBlock: boolean,
    read UsableFromBlock: boolean,

    read ComboWindow: number,

    read AnimationId: string,
    read Reaction: Reactions.ReactionKind,

    -- optional, used for grabbing
    read ReleaseTick: number?
}

return {}