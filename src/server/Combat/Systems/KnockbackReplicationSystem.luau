--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function KnockbackReplicationSystem(tick: number, _delta: number)
    for _entity, knockback, playerRef in World:query(Components.Knockback, Components.PlayerRef):without(Components.Dead) do
        if knockback.StartedAt == tick then
            Packets.Knockback.sendTo({ Velocity = knockback.Velocity, Duration = knockback.EndsAt - knockback.StartedAt }, playerRef)
        end
    end

end

return KnockbackReplicationSystem
