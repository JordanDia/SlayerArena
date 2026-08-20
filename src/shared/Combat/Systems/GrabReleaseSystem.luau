--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const CharacterState = require(ReplicatedStorage.Shared.Combat.CharacterState)
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Abilities = require(ReplicatedStorage.Shared.Combat.Data.Abilities)
const Ragdoll = require(ReplicatedStorage.Shared.Combat.Data.Ragdoll)
const VfxManifest = require(ReplicatedStorage.Shared.Combat.Data.VfxManifest)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function GrabReleaseSystem(tick: number, _delta: number)
    const consumed: { { Victim: World.Entity, Holder: World.Entity } } = {}
    for entity, grabbed in World:query(Components.Grabbed):without(Components.Dead) do

        if tick >= grabbed.ReleasesAt then
            table.insert(consumed, { Victim = entity, Holder = grabbed.Holder })

            const holderCharacterRef = World:get(grabbed.Holder, Components.CharacterRef)
            const victimCharacterRef = World:get(entity, Components.CharacterRef)
            if holderCharacterRef and victimCharacterRef then

                const frameData = Abilities.Get(grabbed.Ability, grabbed.HitIndex)
                const lookVector = holderCharacterRef.Root.CFrame.LookVector
                const knockback: Components.Knockback = {
                    Velocity = lookVector * frameData.KnockbackSpeed + Vector3.yAxis * frameData.KnockbackUpward,
                    StartedAt = tick,
                    EndsAt = tick + frameData.KnockbackDuration,
                }
                World:set(entity, Components.Knockback, knockback)

                if frameData.Ragdoll then
                    const ragdoll: Components.Ragdolled = {}
                    World:set(entity, Components.Ragdolled, ragdoll)
                end

                const stunned = World:get(entity, Components.Stunned)
                if stunned then
                    stunned.EndsAt = tick + frameData.Hitstun
                else
                    const newStunned: Components.Stunned = {
                        StartedAt = tick,
                        EndsAt = tick + frameData.Hitstun,
                        Reaction = frameData.Reaction,
                        Source = grabbed.Holder,
                    }
                    World:set(entity, Components.Stunned, newStunned)
                end
                Packets.Vfx.sendToAll({ Character = victimCharacterRef.Model, Kind = VfxManifest.ReverseMap.Knockback, Duration = frameData.KnockbackDuration })
            end
        end
    end

    for _, entities in consumed do
        World:remove(entities.Victim, Components.Grabbed)
        World:remove(entities.Holder, Components.Holding)
    end

    const removeHolding: { { Victim: World.Entity, Holder: World.Entity } } = {}
    for entity, holding in World:query(Components.Holding):without(Components.Dead) do
        const isDead = World:has(holding.Victim, Components.Dead)
        const isGrabbed = World:has(holding.Victim, Components.Grabbed)
        const holderStunned = World:has(entity, Components.Stunned)
        const holderAttacking = World:has(entity, Components.ActiveAttack)

        if isDead or not isGrabbed or holderStunned or not holderAttacking then
            table.insert(removeHolding, { Victim = holding.Victim, Holder = entity })
        end
    end

    for _, entities in removeHolding do
        World:remove(entities.Holder, Components.Holding)

        if World:has(entities.Victim, Components.Grabbed) then
            World:remove(entities.Victim, Components.Grabbed)
        end

        const thrown = World:get(entities.Victim, Components.Thrown)
        if thrown then
            thrown.EndsAt = tick
        end
    end

    for _entity, thrown, characterRef in World:query(Components.Thrown, Components.CharacterRef):without(Components.Dead) do
        --ExpirySystem will handle it
        if tick >= thrown.MaxEndsAt then continue end

        const grounded = CharacterState.IsGrounded(characterRef)
        const settled = characterRef.Root.AssemblyLinearVelocity.Magnitude < Ragdoll.SettledSpeed

        if not (grounded and settled) then
            thrown.EndsAt = math.max(tick + Ragdoll.GroundTime, thrown.EndsAt)
        end
    end
end

return GrabReleaseSystem
