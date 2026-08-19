
--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function NpcKnockbackSystem(tick: number, _delta: number)
    for _entity, knockback, characterRef in World:query(Components.Knockback, Components.CharacterRef):without(Components.PlayerRef):without(Components.Dead) do
        if knockback.StartedAt ~= tick then return end

        characterRef.Humanoid.PlatformStand = false
        characterRef.Root.AssemblyLinearVelocity = knockback.Velocity
    end
end


return NpcKnockbackSystem