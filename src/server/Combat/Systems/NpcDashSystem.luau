--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Dash = require(ReplicatedStorage.Shared.Combat.Data.Dash)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function NpcDashSystem(_tick: number, _delta: number)
    for _entity, dashing, characterRef in World:query(Components.Dashing, Components.CharacterRef):without(Components.PlayerRef, Components.Dead) do
        -- Dashing.Direction is already world space and flattened, resolved once by
        -- DashSystem. Converting again would rotate it by the character's facing twice.
        if dashing.Direction.Magnitude < 0.001 then continue end

        characterRef.Root.AssemblyLinearVelocity = dashing.Direction.Unit * Dash.Speed
    end
end

return NpcDashSystem
