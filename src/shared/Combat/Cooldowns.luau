--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(script.Parent.Components)
const CooldownDurations = require(ReplicatedStorage.Shared.Combat.Data.CooldownDurations)
const World = require(script.Parent.World)

const Cooldowns = {}

function Cooldowns.IsReady(entity: World.Entity, id: CooldownDurations.CooldownId, tick: number): boolean
    const cooldowns = World:get(entity, Components.Cooldowns)
    if not cooldowns then return true end

    return tick >= (cooldowns[id] or 0) 
end

function Cooldowns.Start(entity: World.Entity, id: CooldownDurations.CooldownId, tick: number)
    local existing: Components.Cooldowns? = World:get(entity, Components.Cooldowns)
    const cooldowns: Components.Cooldowns = existing or {}
    if not existing then
        World:set(entity, Components.Cooldowns, cooldowns)
    end

    cooldowns[id] = tick + CooldownDurations.Get(id)
end

function Cooldowns.IsReadyKey(entity: World.Entity, key: string, tick: number): boolean?
    const cooldowns = World:get(entity, Components.Cooldowns)
    if not cooldowns then return true end

    return tick >= (cooldowns[key] or 0)
end

function Cooldowns.StartKey(entity: World.Entity, key: string, tick: number, duration: number)
    local existing: Components.Cooldowns? = World:get(entity, Components.Cooldowns)
    const cooldowns: Components.Cooldowns = existing or {}
    if not existing then
        World:set(entity, Components.Cooldowns, cooldowns)
    end

    cooldowns[key] = tick + duration
end

return Cooldowns