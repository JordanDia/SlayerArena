--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const CharacterState = require(ReplicatedStorage.Shared.Combat.CharacterState)
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const Ragdoll = require(ReplicatedStorage.Shared.Combat.Data.Ragdoll)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function RagdollSystem(tick: number, _delta: number)

    const toRemove: { { Entity: World.Entity, Facing: Vector3 } } = {}
    for entity, ragdolled in World:query(Components.Ragdolled):without(Components.Thrown, Components.Dead) do
        table.insert(toRemove, { Entity = entity, Facing = ragdolled.Facing })

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

    for _, pending in toRemove do
        World:remove(pending.Entity, Components.Ragdolled)

        const playerRef = World:get(pending.Entity, Components.PlayerRef)
        if playerRef then
            Packets.Getup.sendTo(nil, playerRef)
            continue
        end

        const characterRef = World:get(pending.Entity, Components.CharacterRef)
        if not characterRef then continue end

        CharacterState.SnapUpright(characterRef, pending.Facing)
    end
end

return RagdollSystem
