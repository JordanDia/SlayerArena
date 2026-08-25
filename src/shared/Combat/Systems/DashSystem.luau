--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const CharacterState = require(ReplicatedStorage.Shared.Combat.CharacterState)
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Cooldowns = require(ReplicatedStorage.Shared.Combat.Cooldowns)
const Dash = require(ReplicatedStorage.Shared.Combat.Data.Dash)
const VfxManifest = require(ReplicatedStorage.Shared.Combat.Data.VfxManifest)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const SoundManifest = require(ReplicatedStorage.Shared.Combat.Data.SoundManifest)
const World = require(ReplicatedStorage.Shared.Combat.World)

const DASH_MASK = 3

const function DashSystem(tick: number, _delta: number)
    for entity, dashIntent in World:query(Components.DashIntent):without(Components.Dead) do

        const activeAttack = World:has(entity, Components.ActiveAttack)
        const stunned = World:has(entity, Components.Stunned)
        const actionLock = World:has(entity, Components.ActionLock)
        const blockstun = World:has(entity, Components.Blockstun)

        if activeAttack or stunned or actionLock or blockstun then
            continue
        end

        if not Cooldowns.IsReady(entity, "Dash", tick) then continue end

        const characterRef = World:get(entity, Components.CharacterRef)
        if not characterRef then continue end

        -- Grounded only. Rejecting without removing the intent means a dash buffered
        -- just before landing still fires on the landing tick, rather than being eaten.
        if CharacterState.IsAirborne(characterRef) then continue end

        if World:has(entity, Components.Blocking) then
            World:remove(entity, Components.Blocking)
        end

        Cooldowns.Start(entity, "Dash", tick)

        -- NPCs send no direction, so they fall back to the character-relative vector
        -- for their chosen kind. Resolved to world space once, here, so every consumer
        -- reads the same thing and nothing re-derives it from a rotating character.
        const flat = Vector3.new(dashIntent.Direction.X, 0, dashIntent.Direction.Z)
        const direction = if flat.Magnitude > 0.001
            then flat.Unit
            else CharacterState.YawToWorld(characterRef, Dash.DirectionMap[dashIntent.Kind])

        const newDashing: Components.Dashing = {
            EndsAt = tick + Dash.Duration,
            Direction = direction,
            Kind = dashIntent.Kind,
        }

        World:set(entity, Components.Dashing, newDashing)

        const newActionLock: Components.ActionLock = {
            EndsAt = tick + Dash.Duration,
            Mask = DASH_MASK,
        }
        World:set(entity, Components.ActionLock, newActionLock)

        const playerRef = World:get(entity, Components.PlayerRef)
        if playerRef then
            Packets.Dash.sendTo({
                Direction = newDashing.Direction,
                Speed = Dash.Speed,
                Duration = Dash.Duration,
            }, playerRef)
        end

        Packets.Vfx.sendToAll({
            Character = characterRef.Model,
            Kind = VfxManifest.ReverseMap.Dash,
            Duration = Dash.Duration,
            Position = characterRef.Root.Position,
        })

        Packets.Sound.sendToAll({
            Character = characterRef.Model,
            Kind = SoundManifest.ReverseMap.Dash,
        })

        World:remove(entity, Components.DashIntent)
    end
end

return DashSystem
