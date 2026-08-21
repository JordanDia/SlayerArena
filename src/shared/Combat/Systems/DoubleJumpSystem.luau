--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const DoubleJump = require(ReplicatedStorage.Shared.Combat.Data.DoubleJump)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const World = require(ReplicatedStorage.Shared.Combat.World)

const ANIMATION_TICKS = 20

const function DoubleJumpSystem(tick: number, _delta: number)
    for _entity, characterRef, airJumps in World:query(Components.CharacterRef, Components.AirJumps):without(Components.Dead) do
        if characterRef.Humanoid.FloorMaterial == Enum.Material.Air then continue end
        if airJumps.Used == 0 then continue end

        airJumps.Used = 0
    end

    for entity, doubleJumpIntent, characterRef, airJumps in World:query(Components.DoubleJumpIntent, Components.CharacterRef, Components.AirJumps):without(Components.Dead) do

        const stunned = World:has(entity, Components.Stunned)
        const blockstun = World:has(entity, Components.Blockstun)
        const grabbed = World:has(entity, Components.Grabbed)
        const thrown = World:has(entity, Components.Thrown)

        if stunned or blockstun or grabbed or thrown then continue end
        if characterRef.Humanoid.FloorMaterial ~= Enum.Material.Air then continue end
        if airJumps.Used >= airJumps.Max then continue end

        airJumps.Used += 1

        const localDirection = DoubleJump.DirectionMap[doubleJumpIntent.Kind]
        local velocity

        if localDirection.Magnitude < 0.001 then
            velocity = Vector3.yAxis * DoubleJump.NeutralSpeed
        else
            const worldDirection = characterRef.Root.CFrame:VectorToWorldSpace(localDirection)
            const flat = Vector3.new(worldDirection.X, 0, worldDirection.Z)

            velocity = flat.Unit * DoubleJump.Speed + Vector3.yAxis * DoubleJump.Speed
        end

        const newDoubleJumping: Components.DoubleJumping = {
            EndsAt = tick + ANIMATION_TICKS,
            Kind = doubleJumpIntent.Kind,
        }
        World:set(entity, Components.DoubleJumping, newDoubleJumping)

        const playerRef = World:get(entity, Components.PlayerRef)
        if playerRef then
            Packets.DoubleJump.sendTo({ Velocity = velocity }, playerRef)
        else
            characterRef.Root.AssemblyLinearVelocity = velocity
        end

        World:remove(entity, Components.DoubleJumpIntent)
    end
end

return DoubleJumpSystem
