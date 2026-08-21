--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Dash = require(ReplicatedStorage.Shared.Combat.Data.Dash)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function NpcDashSystem(_tick: number, _delta: number)
    for _entity, dashing, characterRef in World:query(Components.Dashing, Components.CharacterRef):without(Components.PlayerRef, Components.Dead) do
        const worldDirection = characterRef.Root.CFrame:VectorToWorldSpace(dashing.Direction)
        const flat = Vector3.new(worldDirection.X, 0, worldDirection.Z)
        if flat.Magnitude < 0.001 then continue end

        characterRef.Root.AssemblyLinearVelocity = flat.Unit * Dash.Speed
    end
end

return NpcDashSystem
