--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Cooldowns = require(ReplicatedStorage.Shared.Combat.Cooldowns)
const Abilities = require(ReplicatedStorage.Shared.Combat.Data.Abilities)
const World = require(ReplicatedStorage.Shared.Combat.World)

const INTENT_LIFETIME = 4

const function CritSystem(tick: number, _delta: number)
    for entity, critRequested in World:query(Components.CritRequested):without(Components.Dead) do
        if not critRequested.Wants or critRequested.Consumed then continue end
        critRequested.Consumed = true

        if World:has(entity, Components.Stunned) then continue end
        if World:has(entity, Components.ActionLock) then continue end
        if World:has(entity, Components.ActiveAttack) then continue end
        if not Cooldowns.IsReady(entity, "Crit", tick) then continue end

        local ability: Abilities.AbilityId = "Crit"

        if World:has(entity, Components.CritWindow) then
            ability = "CritEmpowered"
            World:remove(entity, Components.CritWindow)
        end

        Cooldowns.Start(entity, "Crit", tick)


        World:remove(entity, Components.Blocking)
        World:remove(entity, Components.Parrying)

        World:set(entity, Components.AttackIntent, {
            Ability = ability,
            ExpiresAt = tick + INTENT_LIFETIME
        })
    end
end

return CritSystem
