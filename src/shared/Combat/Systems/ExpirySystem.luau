--!strict

const Jecs = require("../../../Packages/Jecs")
const Components = require("../Components")
const World = require("../World")

const function GetEndsAt(component: { EndsAt: number}): number
    return component.EndsAt
end

const function GetExpiresAt(component: { ExpiresAt: number}): number
    return component.ExpiresAt
end

const function GetDecaysAt(component: { DecaysAt: number }): number
    return component.DecaysAt
end

const function CheckExpire<T>(component: Jecs.Id<T>, getDeadline: (T) -> number, tick: number)
    const expired = {}
    for entity, value in World:query(component):without(Components.Dead) do
        if tick >= getDeadline(value) then
            table.insert(expired, entity)
        end
    end

    for _, entity in expired do
        World:remove(entity, component)
    end
end

const function ExpirySystem(tick: number, _delta: number)
    CheckExpire(Components.Stunned, GetEndsAt, tick)
    CheckExpire(Components.ActionLock, GetEndsAt, tick)
    CheckExpire(Components.Invulnerable, GetEndsAt, tick)
    CheckExpire(Components.Dashing, GetEndsAt, tick)
    CheckExpire(Components.Knockback, GetEndsAt, tick)
    CheckExpire(Components.ComboChain, GetExpiresAt, tick)
    CheckExpire(Components.ComboCounter, GetDecaysAt, tick)
    CheckExpire(Components.Hitstop, GetEndsAt, tick)
    CheckExpire(Components.Blockstun, GetEndsAt, tick)
    CheckExpire(Components.AttackIntent, GetExpiresAt, tick)
    CheckExpire(Components.DodgeIntent, GetExpiresAt, tick)
    CheckExpire(Components.DashIntent, GetExpiresAt, tick)
    CheckExpire(Components.DoubleJumpIntent, GetExpiresAt, tick)
    CheckExpire(Components.DoubleJumping, GetEndsAt, tick)
    CheckExpire(Components.Thrown, GetEndsAt, tick)
    CheckExpire(Components.Suspended, GetEndsAt, tick)
    CheckExpire(Components.Suspending, GetEndsAt, tick)
    CheckExpire(Components.GroundPinPending, GetEndsAt, tick)
    CheckExpire(Components.GroundPinned, GetEndsAt, tick)
    CheckExpire(Components.JumpLockout, GetEndsAt, tick)
end

return ExpirySystem
