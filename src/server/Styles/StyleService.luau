--!strict
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Styles = require(ReplicatedStorage.Shared.Combat.Data.Styles)
const EntityRegistry = require(ReplicatedStorage.Shared.Combat.EntityRegistry)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const World = require(ReplicatedStorage.Shared.Combat.World)
const chosen: { [Player] : string } = {}

const StyleService = {}


function StyleService:Start()
    Players.PlayerRemoving:Connect(function(player: Player)
        chosen[player] = nil
    end)

    Packets.StyleRequest.listen(function(styleId: string, player: Player?)
        if not player then return end
        if not Styles.Get(styleId :: Styles.StyleId) then return end

        chosen[player] = styleId

        const character = player.Character
        if not character then return end

        const entity = EntityRegistry.Get(character)
        if not entity then return end

        if World:has(entity, Components.ActiveAttack) then return end
        if World:has(entity, Components.Stunned) then return end

        World:set(entity, Components.EquippedStyle, { Style = styleId })
    end)
end

function StyleService:GetStyle(player: Player): string?
    return chosen[player]
end


return StyleService