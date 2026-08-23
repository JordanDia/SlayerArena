--!strict

export type Profile = {
    read Reach: number,
    read PunchTicks: number,
    read Interval: number,
    read Thickness: number,
    read SpreadX: number,
    read SpreadY: number,
    read Curve: number,
    read BurstOffset: number,
}

const GatlingArm: Profile = {
    Reach = 10,
    PunchTicks = 8,
    Interval = 3,
    Thickness = 0.9,
    SpreadX = 4,
    SpreadY = 4,
    Curve = 3,
    BurstOffset = 2,
}

return GatlingArm