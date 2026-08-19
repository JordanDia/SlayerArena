--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Components = require("@game/ReplicatedStorage/Shared/Combat/Components")
const Packets = require("@game/ReplicatedStorage/Shared/Combat/Packets")
const World = require("@game/ReplicatedStorage/Shared/Combat/World")
const Abilities = require(ReplicatedStorage.Shared.Combat.Data.Abilities)
const Scheduler = require(ReplicatedStorage.Shared.Combat.Scheduler)
const CharacterBindingService = require("./CharacterBindingService")

const CombatInputService = {}

function CombatInputService:Start()
    Packets.AttackRequest.listen(function(_data: nil, player: Player?)
        if not player or not player.Character then return end

        const entity = CharacterBindingService.GetEntity(player.Character)
        if not entity then return end
        World:set(entity, Components.AttackIntent, {
            Ability = "M1" :: Abilities.AbilityId,
            ExpiresAt = Scheduler.GetTick() + 4
        })
    end)

    Packets.BlockRequest.listen(function(wants: boolean, player: Player?)
        if not player or not player.Character then return end

        const entity = CharacterBindingService.GetEntity(player.Character)
        if not entity then return end
        World:set(entity, Components.BlockHeld, {
            Wants = wants
        })
    end)

    Packets.GrabRequest.listen(function(_data: nil, player: Player?)
        if not player or not player.Character then return end

        const entity = CharacterBindingService.GetEntity(player.Character)
        if not entity then return end
        World:set(entity, Components.AttackIntent, {
            Ability = "Grab" :: Abilities.AbilityId,
            ExpiresAt = Scheduler.GetTick() + 4
        })
    end)

    Packets.DodgeRequest.listen(function(_data: nil, player: Player?)
        if not player or not player.Character then return end

        const entity = CharacterBindingService.GetEntity(player.Character)
        if not entity then return end
        World:set(entity, Components.DodgeIntent, {
            ExpiresAt = Scheduler.GetTick() + 4 
        })
    end)
end

return CombatInputService