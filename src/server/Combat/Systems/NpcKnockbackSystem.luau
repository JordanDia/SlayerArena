--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function NpcKnockbackSystem(tick: number, _delta: number)
    for _entity, knockback, characterRef in World:query(Components.Knockback, Components.CharacterRef):without(Components.PlayerRef, Components.Dead) do
        if knockback.StartedAt ~= tick then continue end

        characterRef.Root:ApplyImpulse(knockback.Velocity * characterRef.Root.AssemblyMass)
    end
end

return NpcKnockbackSystem
