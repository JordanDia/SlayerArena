--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Ragdoll = require(ReplicatedStorage.Shared.Combat.Data.Ragdoll)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function RagdollSystem(tick: number, _delta: number)

    const toRemove = {}
    for entity in World:query(Components.Ragdolled):without(Components.Thrown, Components.Dead) do
        table.insert(toRemove, entity)

        const actionLock: Components.ActionLock = {
            EndsAt = tick + Ragdoll.GetupDuration,
            Mask = 2,
        }
        World:set(entity, Components.ActionLock, actionLock)

        const invulnerable: Components.Invulnerable = {
            StartsAt = tick,
            EndsAt = tick + Ragdoll.GetupDuration,
            Kind = "Getup"
        }
        World:set(entity, Components.Invulnerable, invulnerable)
    end

    for _, entity in toRemove do
        World:remove(entity, Components.Ragdolled)
    end
end

return RagdollSystem
