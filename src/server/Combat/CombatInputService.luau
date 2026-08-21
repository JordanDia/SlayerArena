--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Components = require("@game/ReplicatedStorage/Shared/Combat/Components")
const Packets = require("@game/ReplicatedStorage/Shared/Combat/Packets")
const World = require("@game/ReplicatedStorage/Shared/Combat/World")
const Abilities = require(ReplicatedStorage.Shared.Combat.Data.Abilities)
const Dash = require(ReplicatedStorage.Shared.Combat.Data.Dash)
const DoubleJump = require(ReplicatedStorage.Shared.Combat.Data.DoubleJump)
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

    Packets.UptiltRequest.listen(function(wants: boolean, player: Player?)
        if not player or not player.Character then return end

        const entity = CharacterBindingService.GetEntity(player.Character)
        if not entity then return end
        World:set(entity, Components.UptiltHeld, {
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

    Packets.DoubleJumpRequest.listen(function(directionByte: number, player: Player?)
        if not player or not player.Character then return end

        const doubleJumpKind = DoubleJump.ByteMap[directionByte]
        if not doubleJumpKind then return end

        const entity = CharacterBindingService.GetEntity(player.Character)
        if not entity then return end

        const doubleJumpIntent: Components.DoubleJumpIntent = {
            Kind = doubleJumpKind,
            ExpiresAt = Scheduler.GetTick() + 4
        }
        World:set(entity, Components.DoubleJumpIntent, doubleJumpIntent)
    end)

    Packets.DashRequest.listen(function(directionByte: number, player: Player?)
        if not player or not player.Character then return end

        const dashKind = Dash.ByteMap[directionByte]
        if not dashKind then return end

        const entity = CharacterBindingService.GetEntity(player.Character)
        if not entity then return end

        const dashIntent: Components.DashIntent = {
            Kind = dashKind,
            ExpiresAt = Scheduler.GetTick() + 4
        }
        World:set(entity, Components.DashIntent, dashIntent)
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