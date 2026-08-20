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
        const frameData = Abilities.Get(attackIntent.Ability, hitIndex)

        -- reject if these are true
        const attacking = World:has(entity, Components.ActiveAttack)
        const stunned = World:has(entity, Components.Stunned)
        const actionLocked = World:has(entity, Components.ActionLock)
        const blocking = World:has(entity, Components.Blocking)
        const blockstun = World:has(entity, Components.Blockstun)

        if attacking or stunned or actionLocked or blockstun then continue end
        if blocking and not frameData.UsableFromBlock then continue end

        -- did not reject, so begin new attack        
        const comboChain = World:get(entity, Components.ComboChain)
        if comboChain and comboChain.Ability == attackIntent.Ability then
            hitIndex = (comboChain.Index % Abilities.Length(attackIntent.Ability)) + 1
        end

        const newActiveAttack: Components.ActiveAttack = {
            Ability = attackIntent.Ability,
            HitIndex = hitIndex,
            StartedAt = tick,
            HasHit = {},
            FiredVfx = {},
            PausedTicks = 0,
        }
        World:set(entity, Components.ActiveAttack, newActiveAttack)
        World:remove(entity, Components.Blocking)

        const newComboChain: Components.ComboChain = {
            Index = hitIndex,
            ExpiresAt = tick + frameData.ComboWindow,
            Ability = attackIntent.Ability
        }
        World:set(entity, Components.ComboChain, newComboChain)

        const newActionLock: Components.ActionLock = {
            EndsAt = tick + frameData.Startup + frameData.Active + frameData.Recovery,
            Mask = 1,
        }
        World:set(entity, Components.ActionLock, newActionLock)

        World:remove(entity, Components.AttackIntent)
    end

end

return AttackSystem
