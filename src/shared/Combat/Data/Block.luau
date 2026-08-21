--!strict

export type BlockData = {
    read DrainPerTick: number,
    read RegenPerTick: number,
    read RegenDelay: number,

    read ReleaseLag: number,

    read PushbackSpeed: number,
    read PushbackDuration: number,
    read GuardBreakStun: number,

    read MinPostureToBlock: number,

    read PerfectWindow: number,
    read PerfectBlockstun: number,
    read PerfectFreeze: number,
}

const Block: BlockData = {
    DrainPerTick = 0.2,
    RegenPerTick = 1,
    RegenDelay = 120,

    ReleaseLag = 8,

    PushbackSpeed = 3,
    PushbackDuration = 5,
    GuardBreakStun = 120,

    MinPostureToBlock = 5,

    PerfectWindow = 5,
    PerfectBlockstun = 2,
    PerfectFreeze = 120,
}

return table.freeze(Block)