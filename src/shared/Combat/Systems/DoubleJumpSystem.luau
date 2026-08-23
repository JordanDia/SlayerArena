--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const CharacterState = require(ReplicatedStorage.Shared.Combat.CharacterState)
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Cooldowns = require(ReplicatedStorage.Shared.Combat.Cooldowns)
const DoubleJump = require(ReplicatedStorage.Shared.Combat.Data.DoubleJump)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const SoundManifest = require(ReplicatedStorage.Shared.Combat.Data.SoundManifest)
const VfxManifest = require(ReplicatedStorage.Shared.Combat.Data.VfxManifest)
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
        const activeAttack = World:has(entity, Components.ActiveAttack)
        const actionLock = World:has(entity, Components.ActionLock)
        const jumpLockout = World:has(entity, Components.JumpLockout)
        const suspended = World:has(entity, Components.Suspended)
        const suspending = World:has(entity, Components.Suspending)

        if suspended or suspending or jumpLockout or stunned or blockstun or grabbed or thrown or activeAttack or actionLock then continue end
        if characterRef.Humanoid.FloorMaterial ~= Enum.Material.Air then continue end
        if airJumps.Used >= airJumps.Max then continue end
        if not Cooldowns.IsReady(entity, "AirJump", tick) then continue end

        airJumps.Used += 1
        Cooldowns.Start(entity, "AirJump", tick)

        const localDirection = DoubleJump.DirectionMap[doubleJumpIntent.Kind]
        local velocity

        if localDirection.Magnitude < 0.001 then
            velocity = Vector3.yAxis * DoubleJump.NeutralSpeed
        else
            -- The camera-relative vector the client actually aimed with. Kind only picks
            -- the animation: resolving the direction from Kind instead would quantise it
            -- to four character-relative axes, up to 45 degrees off what was pressed.
            -- NPCs send nothing, so they fall back to their own facing, yaw only.
            const direction = if doubleJumpIntent.Direction.Magnitude > 0.001
                then doubleJumpIntent.Direction
                else CharacterState.YawToWorld(characterRef, localDirection)

            -- Speed is the vertical component and the horizontal one is derived from
            -- Angle, so changing the angle re-aims the jump without changing its height.
            const horizontal = DoubleJump.Speed / math.tan(math.rad(DoubleJump.Angle))
            velocity = direction * horizontal + Vector3.yAxis * DoubleJump.Speed
        end

        const newDoubleJumping: Components.DoubleJumping = {
            EndsAt = tick + ANIMATION_TICKS,
            Kind = doubleJumpIntent.Kind,
        }
        World:set(entity, Components.DoubleJumping, newDoubleJumping)

        -- Sent to everyone, unlike the DoubleJump packet itself, which only the
        -- jumping player needs. Direction rides along because a spectator cannot
        -- work out which way somebody else jumped.
        Packets.Vfx.sendToAll({
            Character = characterRef.Model,
            Kind = VfxManifest.ReverseMap.Geppo,
            Duration = 0,
            Direction = velocity.Unit,
        })

        Packets.Sound.sendToAll({
            Character = characterRef.Model,
            Kind = SoundManifest.ReverseMap.Geppo,
        })

        const playerRef = World:get(entity, Components.PlayerRef)
        if playerRef then
            Packets.DoubleJump.sendTo({ Velocity = velocity }, playerRef)
        else
            characterRef.Root.AssemblyLinearVelocity = Vector3.zero
            characterRef.Root.AssemblyAngularVelocity = Vector3.zero
            characterRef.Root.AssemblyLinearVelocity = velocity
        end

        World:remove(entity, Components.DoubleJumpIntent)
    end
end

return DoubleJumpSystem
