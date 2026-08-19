--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Abilities = require(ReplicatedStorage.Shared.Combat.Data.Abilities)
const World = require("./World")

const HitQueue = {}

export type PendingHit = {
    Attacker: World.Entity,
    Target: World.Entity,
    Ability: Abilities.AbilityId,
    HitIndex: number,
    Tick: number,
    Position: Vector3
}

const queueA: { PendingHit } = {}
const queueB: { PendingHit } = {}
const queues: { { PendingHit } } = { queueA, queueB }
local liveIndex = 1


function HitQueue.Push(hit: PendingHit)
    const queue = queues[liveIndex]
    table.insert(queue, hit)
end

-- before I cloned the queue and returned it, clearing the old one
-- that clones a table each tick, so we just have two queues, and swap the live pointer whenever we need to
-- drained table is only valid until next call
function HitQueue.Drain(): { PendingHit }
    const liveQueue = queues[liveIndex]
    liveIndex = 3 - liveIndex
    table.clear(queues[liveIndex])
    return liveQueue
end

return HitQueue