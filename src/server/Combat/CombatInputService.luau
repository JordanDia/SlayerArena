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

    Packets.DoubleJumpRequest.listen(function(data: { Kind: number, Direction: Vector3 }, player: Player?)
        if not player or not player.Character then return end

        const doubleJumpKind = DoubleJump.ByteMap[data.Kind]
        if not doubleJumpKind then return end

        const entity = CharacterBindingService.GetEntity(player.Character)
        if not entity then return end

        const flat = Vector3.new(data.Direction.X, 0, data.Direction.Z)

        const doubleJumpIntent: Components.DoubleJumpIntent = {
            Kind = doubleJumpKind,
            ExpiresAt = Scheduler.GetTick() + 4,
            Direction = if flat.Magnitude > 0.001 then flat.Unit else Vector3.zero,
        }
        World:set(entity, Components.DoubleJumpIntent, doubleJumpIntent)
    end)

    Packets.DashRequest.listen(function(data: { Kind: number, Direction: Vector3 }, player: Player?)
        if not player or not player.Character then return end

        const dashKind = Dash.ByteMap[data.Kind]
        if not dashKind then return end

        const entity = CharacterBindingService.GetEntity(player.Character)
        if not entity then return end

        -- Flatten and normalise here rather than trusting the client's magnitude. The
        -- direction itself is not worth validating harder than this: a player can already
        -- aim a dash anywhere by turning the camera.
        const flat = Vector3.new(data.Direction.X, 0, data.Direction.Z)
        const direction = if flat.Magnitude > 0.001 then flat.Unit else Vector3.zero

        const dashIntent: Components.DashIntent = {
            Kind = dashKind,
            ExpiresAt = Scheduler.GetTick() + 4,
            Direction = direction,
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