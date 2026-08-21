--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Abilities = require(ReplicatedStorage.Shared.Combat.Data.Abilities)
const Components = require("../Components")
const World = require("../World")

const function AttackSystem(tick: number, _delta: number)
    const finishedAttacks = {}

    for entity, activeAttack in World:query(Components.ActiveAttack):without(Components.Dead) do
        const frameData = Abilities.Get(activeAttack.Ability, activeAttack.HitIndex)

        const totalDuration = frameData.Startup + frameData.Active + frameData.Recovery
        if tick >= activeAttack.StartedAt + totalDuration + activeAttack.PausedTicks then
            table.insert(finishedAttacks, entity)
        end
    end

    for _, entity in finishedAttacks do
        World:remove(entity, Components.ActiveAttack)
    end

    for entity, attackIntent in World:query(Components.AttackIntent):without(Components.Dead) do
        
        local hitIndex = 1
        local ability = attackIntent.Ability

        -- Mid-float, M1 means the two hit air string instead of the ground one. This
        -- has to precede the chain resolution below, because the chain must be
        -- resolved against "Air" - the uptilt swap cannot, since it needs the
        -- resolved index to know it is on the last hit.
        if ability == "M1" and World:has(entity, Components.Suspending) then
            ability = "Air"
        end

        -- did not reject, so begin new attack        
        const comboChain = World:get(entity, Components.ComboChain)
        if comboChain and comboChain.Ability == ability then
            hitIndex = (comboChain.Index % Abilities.Length(ability)) + 1
        end

        -- reject if these are true
        const attacking = World:has(entity, Components.ActiveAttack)
        const stunned = World:has(entity, Components.Stunned)
        const actionLocked = World:has(entity, Components.ActionLock)
        const blocking = World:has(entity, Components.Blocking)
        const blockstun = World:has(entity, Components.Blockstun)
    
        -- ability is M1 by default, now we check hit index and uptilt
        const uptilt: Components.UptiltHeld? = World:get(entity, Components.UptiltHeld)
        if uptilt and uptilt.Wants and hitIndex == Abilities.Length("M1") and ability == "M1" then
            ability = "Uptilt"
            hitIndex = 1
        end

        const frameData = Abilities.Get(ability, hitIndex)
        if attacking or stunned or actionLocked or blockstun then continue end
        if blocking and not frameData.UsableFromBlock then continue end

        const newActiveAttack: Components.ActiveAttack = {
            Ability = ability,
            HitIndex = hitIndex,
            StartedAt = tick,
            HasHit = {},
            FiredVfx = {},
            PausedTicks = 0,
        }
        World:set(entity, Components.ActiveAttack, newActiveAttack)
        World:remove(entity, Components.Blocking)

        print(newActiveAttack.Ability, newActiveAttack.HitIndex)

        const newComboChain: Components.ComboChain = {
            Index = hitIndex,
            ExpiresAt = tick + frameData.ComboWindow,
            Ability = ability
        }
        World:set(entity, Components.ComboChain, newComboChain)

        const newActionLock: Components.ActionLock = {
            EndsAt = tick + frameData.Startup + frameData.Active + frameData.Recovery,
            Mask = 1,
        }
        World:set(entity, Components.ActionLock, newActionLock)

        const jumpLockout: Components.JumpLockout = {
            EndsAt = tick + frameData.Startup + frameData.Active + frameData.Recovery + frameData.JumpLockoutTicks
        }
        World:set(entity, Components.JumpLockout, jumpLockout)

        World:remove(entity, Components.AttackIntent)
    end

end

return AttackSystem
