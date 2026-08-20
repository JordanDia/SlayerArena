
--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function NpcKnockbackSystem(tick: number, _delta: number)
    for entity, knockback, characterRef in World:query(Components.Knockback, Components.CharacterRef):without(Components.PlayerRef, Components.Dead) do
        if knockback.StartedAt ~= tick then continue end


        if not World:has(entity, Components.Thrown) then
            characterRef.Humanoid.PlatformStand = false
        else
            characterRef.Humanoid.PlatformStand = true
        end
        characterRef.Root.AssemblyLinearVelocity = knockback.Velocity
    end
end


return NpcKnockbackSystem