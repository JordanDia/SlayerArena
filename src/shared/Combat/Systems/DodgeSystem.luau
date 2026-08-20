--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const CharacterState = require(ReplicatedStorage.Shared.Combat.CharacterState)
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Cooldowns = require(ReplicatedStorage.Shared.Combat.Cooldowns)
const Dodge = require(ReplicatedStorage.Shared.Combat.Data.Dodge)
const VfxManifest = require(ReplicatedStorage.Shared.Combat.Data.VfxManifest)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function DodgeSystem(tick: number, _delta: number)
    for entity, _dodgeIntent in World:query(Components.DodgeIntent):without(Components.Dead) do

        const activeAttack = World:has(entity, Components.ActiveAttack)
        const stunned = World:has(entity, Components.Stunned)
        const actionLock = World:has(entity, Components.ActionLock)
        const blockstun = World:has(entity, Components.Blockstun)

        if activeAttack or stunned or actionLock or blockstun then
            continue
        end

        const characterRef = World:get(entity, Components.CharacterRef)
        if not characterRef then continue end

        const grounded = CharacterState.IsGrounded(characterRef)
        const cost = if grounded then Dodge.PostureCost else Dodge.AirPostureCost

        if not grounded and not Cooldowns.IsReady(entity, "AirDodge", tick) then continue end

        const posture = World:get(entity, Components.Posture)
        if not posture then continue end
        if posture.Current < cost then continue end

        if World:has(entity, Components.Blocking) then
            World:remove(entity, Components.Blocking)
        end

        posture.Current -= cost
        posture.LastDamagedTick = tick

        World:set(entity, Components.ActionLock, {
            EndsAt = tick + Dodge.Startup + Dodge.Invulnerable + Dodge.Recovery,
            Mask = 2
        })

        World:set(entity, Components.Invulnerable, {
            StartsAt = tick + Dodge.Startup,
            EndsAt = tick + Dodge.Startup + Dodge.Invulnerable,
            Kind = "Dodge"
        } :: Components.Invulnerable)

        if characterRef.Humanoid:GetState() == Enum.HumanoidStateType.Jumping or characterRef.Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
            local velocity = Vector3.yAxis * Dodge.AirJumpSpeed
            local endsAt = tick + 1
            -- const moveDirection = characterRef.Humanoid.MoveDirection
            -- if moveDirection.Magnitude < 0.1 then
            --     velocity = Vector3.yAxis * Dodge.AirJumpSpeed
            --     endsAt = tick + 1
            -- else
            --     velocity = moveDirection * Dodge.AirSpeed
            --     endsAt = tick + Dodge.AirDuration
            -- end

            const knockback: Components.Knockback = {
                Velocity = velocity,
                StartedAt = tick,
                EndsAt = endsAt,
            }
            World:set(entity, Components.Knockback, knockback)
        end
        Packets.Vfx.sendToAll({
            Character = characterRef.Model,
            Kind = VfxManifest.ReverseMap.Dodge,
            Duration = 0
        })

        World:remove(entity, Components.DodgeIntent)
    end
end

return DodgeSystem