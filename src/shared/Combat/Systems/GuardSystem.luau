--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Cooldowns = require(ReplicatedStorage.Shared.Combat.Cooldowns)
const Abilities = require(ReplicatedStorage.Shared.Combat.Data.Abilities)
const Block = require(ReplicatedStorage.Shared.Combat.Data.Block)
const Parry = require(ReplicatedStorage.Shared.Combat.Data.Parry)
const Reactions = require(ReplicatedStorage.Shared.Combat.Data.Reactions)
const World = require(ReplicatedStorage.Shared.Combat.World)

const GUARDABLE_STUNS: { [Reactions.ReactionKind]: boolean } = {
    Light = true,
    Heavy = true,
    Launch = true,
}

const function CanGuard(entity: World.Entity): boolean
    const stunned = World:get(entity, Components.Stunned)
    if not stunned then return true end

    return GUARDABLE_STUNS[stunned.Reaction] == true
end

const function ParryWindowFor(entity: World.Entity, tick: number)
    const chain = World:get(entity, Components.ParryChain)
    if not chain or tick >= chain.DecaysAt then return Parry.Window end

    return math.max(Parry.WindowMin, Parry.Window - Parry.ChainStep * chain.Count)
end


const function GuardSystem(tick: number, _delta: number)

    -- PASS 1
    for entity, guardHeld in World:query(Components.GuardHeld):without(Components.Dead) do

        if not guardHeld.Wants or guardHeld.Consumed then continue end
        guardHeld.Consumed = true

        if not CanGuard(entity) then continue end

        const activeAttack = World:get(entity, Components.ActiveAttack)
        if activeAttack then
            const frameData = Abilities.Get(activeAttack.Ability, activeAttack.HitIndex)
            const inStartup = tick < activeAttack.StartedAt + frameData.Startup + activeAttack.PausedTicks

            -- Feint
            if inStartup and frameData.Feintable ~= false and Cooldowns.IsReady(entity, "Feint", tick) then
                Cooldowns.Start(entity, "Feint", tick)

                World:remove(entity, Components.ActiveAttack)
                World:remove(entity, Components.ComboChain)

                World:set(entity, Components.ActionLock, {
                    EndsAt = tick + Parry.FeintLock,
                    Mask = 1,
                    })
            end

            continue
        end

        const blocking = World:has(entity, Components.Blocking)
        const actionLocked = World:has(entity, Components.ActionLock)
        if blocking or actionLocked then continue end

        -- Parry
        World:set(entity, Components.Parrying, {
            StartedAt = tick,
            EndsAt = tick + ParryWindowFor(entity, tick)
        })

        const chain = World:get(entity, Components.ParryChain)
        if chain and tick < chain.DecaysAt then
            chain.Count += 1
            chain.DecaysAt = tick + Parry.ChainDecay
        else
            World:set(entity, Components.ParryChain, { Count = 1, DecaysAt = tick + Parry.ChainDecay })
        end

    end

    -- PASS 2: remove parry component once window expires
    for entity, parrying in World:query(Components.Parrying):without(Components.Dead) do
        if tick < parrying.EndsAt then continue end

        World:remove(entity, Components.Parrying)
    end

    -- PASS 3: still holding, didn't parry or feint, so block
    for entity, guardHeld in World:query(Components.GuardHeld):without(Components.Dead) do
        if not guardHeld.Wants then continue end

        const blocking = World:has(entity, Components.Blocking)
        const actionLock = World:has(entity, Components.ActionLock)
        const activeAttack = World:has(entity, Components.ActiveAttack)
        if blocking or actionLock or activeAttack then continue end
        if not CanGuard(entity) then continue end

        World:set(entity, Components.Blocking, { Since = tick })
    end

    -- releasing block, wants = false
    for entity, guardHeld in World:query(Components.GuardHeld):without(Components.Dead) do
        if guardHeld.Wants then continue end

        World:remove(entity, Components.Parrying)

        if not World:has(entity, Components.Blocking) then continue end
        if World:has(entity, Components.Blockstun) then continue end

        World:remove(entity, Components.Blocking)

        const actionLock = World:get(entity, Components.ActionLock)
        if actionLock then
            actionLock.EndsAt = math.max(tick + Block.ReleaseLag, actionLock.EndsAt)
            actionLock.Mask = 1
        else
            World:set(entity, Components.ActionLock, { EndsAt = tick + Block.ReleaseLag, Mask = 1 })
        end
    end
end

return GuardSystem
