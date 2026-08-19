--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Scheduler = require(ReplicatedStorage.Shared.Combat.Scheduler)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function DummyBehaviorSystem(tick: number, _delta: number)
    for entity, dummyBehavior in World:query(Components.DummyBehavior):without(Components.Dead) do
        const activeAttack = World:has(entity, Components.ActiveAttack)
        const actionLock = World:has(entity, Components.ActionLock)
        const stunned = World:has(entity, Components.Stunned)
        const blockstun = World:has(entity, Components.Blockstun)

        if activeAttack or actionLock or stunned or blockstun then
            if blockstun then
                dummyBehavior.ArmedUntil = tick + 1
            end
            dummyBehavior.NextActionAt = tick + dummyBehavior.Interval
            continue
        end

        if tick < dummyBehavior.NextActionAt then continue end

        if dummyBehavior.Policy == "Swinging" then
            World:set(entity, Components.AttackIntent, {
                Ability = "M1",
                ExpiresAt = Scheduler.GetTick() + 4
            } :: Components.AttackIntent)

        elseif dummyBehavior.Policy == "Punisher" then
            if tick > dummyBehavior.ArmedUntil then continue end

            World:set(entity, Components.AttackIntent, {
                Ability = "Grab",
                ExpiresAt = Scheduler.GetTick() + 4
            } :: Components.AttackIntent)

            dummyBehavior.ArmedUntil = 0
        end
    end


end


return DummyBehaviorSystem
