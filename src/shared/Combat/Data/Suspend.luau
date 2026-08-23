--!strict

const Suspend = {
    -- How high a suspend lifts the victim, in studs, before any ceiling clamp.
    Height = 10,

    -- Ticks spent travelling from the ground to Height. The float begins after this.
    RiseTicks = 12,

    -- Clearance kept between the top of the cast box and whatever is above it.
    CeilingMargin = 3,

    -- Box used for the headroom cast. Wider than a character on purpose:
    -- a launch that ends with a shoulder inside a beam is worse than one that stops short.
    CastSize = Vector3.new(4, 5, 4),

    -- How far in front of the attacker the victim is held, in studs.
    VictimDistance = 2,

    -- Must comfortably exceed assembly mass * gravity or the victim visibly sags.
    MaxForce = 100000,

    -- Near-rigid. The rise curve is authored in ticks by SuspendSystem, not by this spring.
    Responsiveness = 200,
}

return table.freeze(Suspend)
