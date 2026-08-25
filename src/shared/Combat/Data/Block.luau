--!strict

export type BlockData = {
    read ChipMultiplier: number,
    read PostureGainMultiplier: number,

    read DecayDelay: number,
    read DecayPerTick: number,

    read ReleaseLag: number,

    read PushbackSpeed: number,
    read PushbackDuration: number,
    read GuardBreakStun: number,
}

const Block: BlockData = {
    ChipMultiplier = 0.2,
    PostureGainMultiplier = 1,

    DecayDelay = 90,
    DecayPerTick = 0.5,

    ReleaseLag = 8,

    PushbackSpeed = 0,
    PushbackDuration = 0,
    GuardBreakStun = 120,
}

return table.freeze(Block)