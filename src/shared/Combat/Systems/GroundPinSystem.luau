--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Ragdoll = require(ReplicatedStorage.Shared.Combat.Data.Ragdoll)
const SoundManifest = require(ReplicatedStorage.Shared.Combat.Data.SoundManifest)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const VfxManifest = require(ReplicatedStorage.Shared.Combat.Data.VfxManifest)
const Components = require("../Components")
const Headroom = require("../Headroom")
const World = require("../World")

--[[
    Turns a pending pin into an active one the tick the body reaches the ground.

    Ground contact is a downward cast rather than Humanoid.FloorMaterial: a ragdolled
    character is PlatformStanding with its state machine effectively off, so the
    Humanoid's own idea of what it is standing on is not trustworthy here.
]]
const function GroundPinSystem(tick: number, _delta: number)
    const landed: { { Entity: World.Entity, PinTicks: number, Position: Vector3, Ground: Vector3, Model: Model } } = {}

    for entity, pending, characterRef in World:query(Components.GroundPinPending, Components.CharacterRef):without(Components.Dead) do
        const travel = -Vector3.yAxis * Ragdoll.PinSettleDistance
        const distance = Headroom.Resolve(characterRef.Root.Position, Ragdoll.PinCastSize, travel, 0, { characterRef.Model })

        if distance >= Ragdoll.PinSettleDistance then continue end

        -- Pin at the ground the cast found, not at wherever they happened to be when it
        -- found it. Triggering a little early is then harmless - the constraint drags
        -- them the last stud or two down, which reads as the impact itself.
        const groundPosition = characterRef.Root.Position - Vector3.yAxis * distance
        const pinPosition = groundPosition + Vector3.yAxis * Ragdoll.PinRestHeight

        table.insert(landed, { Entity = entity, PinTicks = pending.PinTicks, Position = pinPosition, Ground = groundPosition, Model = characterRef.Model })
    end

    for _, pending in landed do
        World:remove(pending.Entity, Components.GroundPinPending)

        Packets.Sound.sendToAll({
            Character = pending.Model,
            Kind = SoundManifest.ReverseMap.GroundSlam,
        })

        Packets.Vfx.sendToAll({
            Character = pending.Model,
            Kind = VfxManifest.ReverseMap.GroundSlam,
            Duration = 0,
            Position = pending.Ground,
        })

        const endsAt = tick + pending.PinTicks
        World:set(pending.Entity, Components.GroundPinned, { EndsAt = endsAt, Position = pending.Position })

        -- RagdollSystem stands them up the moment Thrown expires, so the throw has to
        -- outlast the pin or they would get up while still held down.
        const thrown = World:get(pending.Entity, Components.Thrown)
        if thrown then
            thrown.EndsAt = math.max(thrown.EndsAt, endsAt)
            thrown.MaxEndsAt = math.max(thrown.MaxEndsAt, endsAt)
        end

        const stunned = World:get(pending.Entity, Components.Stunned)
        if stunned then
            stunned.EndsAt = math.max(stunned.EndsAt, endsAt)
        end
    end
end

return GroundPinSystem
