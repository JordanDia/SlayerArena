--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Abilities = require(ReplicatedStorage.Shared.Combat.Data.Abilities)
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function Release(entity: World.Entity, charging: Components.Charging)
    if charging.Frozen then
        for track, speed in charging.Frozen do
            track:AdjustSpeed(speed)
        end
    end

    World:remove(entity, Components.Charging)
end

const function ChargeSystem(tick: number, _delta: number)
    for entity, activeAttack, animationTracks in World:query(Components.ActiveAttack, Components.AnimationTracks):without(Components.Dead) do
        const charging = World:get(entity, Components.Charging)
        const frameData = Abilities.Get(activeAttack.Ability, activeAttack.HitIndex)

        if not frameData.Chargeable then
            if charging then
                Release(entity, charging)
            end
            continue
        end

        -- Held one tick short of the active window so the release tick is the tick the
        -- hitbox and the arm VFX both go live.
        const elapsed = tick - activeAttack.StartedAt - activeAttack.PausedTicks
        if elapsed < frameData.Startup - 1 then continue end

        const skillHeld = World:get(entity, Components.SkillHeld)
        const held = skillHeld ~= nil and skillHeld.Wants
        const expired = charging ~= nil and tick - charging.StartedAt >= (frameData.MaxChargeTicks or 0)

        if not held or expired then
            if charging then
                Release(entity, charging)
            end
            continue
        end

        if not charging then
            const frozen: { [AnimationTrack]: number } = {}
            for _, track in animationTracks do
                if not track.IsPlaying then continue end
                frozen[track] = track.Speed
                track:AdjustSpeed(0)
            end

            World:set(entity, Components.Charging, {
                StartedAt = tick,
                Frozen = frozen,
            })
        end

        activeAttack.PausedTicks += 1

        const actionLock = World:get(entity, Components.ActionLock)
        if actionLock then
            actionLock.EndsAt += 1
        end

        const jumpLockout = World:get(entity, Components.JumpLockout)
        if jumpLockout then
            jumpLockout.EndsAt += 1
        end
    end

    -- Anything that ends the attack early - a hit, a death - leaves these behind with a
    -- frozen animation and an anchored character, so they are cleaned up here rather
    -- than at each of those sites.
    const orphaned: { { Entity: World.Entity, Charging: Components.Charging } } = {}
    for entity, charging in World:query(Components.Charging) do
        if World:has(entity, Components.ActiveAttack) then continue end
        table.insert(orphaned, { Entity = entity, Charging = charging })
    end

    for _, entry in orphaned do
        Release(entry.Entity, entry.Charging)
    end

    -- Facing follows the camera through startup only. Charging holds elapsed one tick
    -- short of Startup, so this releases on the tick the hitbox goes live.
    const unaimed: { World.Entity } = {}
    for entity in World:query(Components.FacingLocked) do
        const activeAttack = World:get(entity, Components.ActiveAttack)
        if not activeAttack then
            table.insert(unaimed, entity)
            continue
        end

        const frameData = Abilities.Get(activeAttack.Ability, activeAttack.HitIndex)
        const elapsed = tick - activeAttack.StartedAt - activeAttack.PausedTicks
        if elapsed >= frameData.Startup then
            table.insert(unaimed, entity)
        end
    end

    for _, entity in unaimed do
        const playerRef = World:get(entity, Components.PlayerRef)
        if playerRef then
            Packets.FacingLock.sendTo(false, playerRef)
        end

        World:remove(entity, Components.FacingLocked)
    end

    -- The freeze ends with the hitbox, not with the attack. Holding it through recovery
    -- leaves the humanoid platform standing long enough that it trips on the way out, or
    -- stumbles on landing when the attack was used in the air. Recovery still locks
    -- movement through ActionLock, so nothing is gained by staying frozen for it.
    const thawed: { World.Entity } = {}
    for entity in World:query(Components.FrozenInPlace) do
        if World:has(entity, Components.ActiveAttack) then continue end
    end

    for _, entity in thawed do
        const playerRef = World:get(entity, Components.PlayerRef)
        if playerRef then
            Packets.ChargeFreeze.sendTo(false, playerRef)
        end

        World:remove(entity, Components.FrozenInPlace)
    end
end

return ChargeSystem
