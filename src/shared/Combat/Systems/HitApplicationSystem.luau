--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Abilities = require(ReplicatedStorage.Shared.Combat.Data.Abilities)
const Block = require(ReplicatedStorage.Shared.Combat.Data.Block)
const Ragdoll = require(ReplicatedStorage.Shared.Combat.Data.Ragdoll)
const Suspend = require(ReplicatedStorage.Shared.Combat.Data.Suspend)
const VfxManifest = require(ReplicatedStorage.Shared.Combat.Data.VfxManifest)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const Components = require("../Components")
const Headroom = require("../Headroom")
const HitQueue = require("../HitQueue")
const World = require("../World")

const COMBO_COUNTER_DECAY_OFFSET = 20
const THROW_MAX_PAD = 120

const function HitApplicationSystem(tick: number, _delta: number)

    for _, hit in HitQueue.Drain() do
        const frameData = Abilities.Get(hit.Ability, hit.HitIndex)

        const invulnerable = World:get(hit.Target, Components.Invulnerable)
        if invulnerable and tick >= invulnerable.StartsAt then continue end
        
        const blocking = World:get(hit.Target, Components.Blocking)
        if blocking and not frameData.IgnoresBlock then
            const perfect = tick - blocking.Since <= Block.PerfectWindow
            const blockstunTicks = if perfect then Block.PerfectBlockstun else frameData.Blockstun

            const postureComponent = World:get(hit.Target, Components.Posture)
            if postureComponent and not perfect then
                postureComponent.Current -= frameData.PostureDamage
                postureComponent.Current = math.max(0, postureComponent.Current)
                postureComponent.LastDamagedTick = tick
            end

            const blockstun = World:get(hit.Target, Components.Blockstun)
            if blockstun then
                blockstun.EndsAt = math.max(tick + blockstunTicks, blockstun.EndsAt)
            else
                World:set(hit.Target, Components.Blockstun, {
                    EndsAt = tick + blockstunTicks
                })
            end

            const attackerCharacterRef = World:get(hit.Attacker, Components.CharacterRef)
            if attackerCharacterRef and not perfect then

                const lookVector = attackerCharacterRef.Root.CFrame.LookVector
                const knockbackVelocity = lookVector * Block.PushbackSpeed
                const knockback: Components.Knockback = {
                    StartedAt = tick,
                    EndsAt = tick + Block.PushbackDuration,
                    Velocity = knockbackVelocity
                }
                World:set(hit.Target, Components.Knockback, knockback)
            end

            -- const activeAttack = World:get(hit.Attacker, Components.ActiveAttack)
            -- if activeAttack then
            --     const attackerFree = activeAttack.StartedAt + frameData.Startup + frameData.Active + frameData.Recovery + activeAttack.PausedTicks
            --     const defenderFree = tick + blockstunTicks
            --     const advantage = defenderFree - attackerFree

            --     print(advantage)
            -- end

            if perfect then
                World:remove(hit.Attacker, Components.ActiveAttack)
                World:remove(hit.Attacker, Components.ActionLock)
                World:remove(hit.Attacker, Components.ComboChain)

                const parried: Components.Stunned = {
                    StartedAt = tick,
                    EndsAt = tick + Block.PerfectFreeze,
                    Reaction = "Parried",
                    Source = hit.Target,
                }
                World:set(hit.Attacker, Components.Stunned, parried)

                if attackerCharacterRef then
                    Packets.Vfx.sendToAll({
                        Character = attackerCharacterRef.Model,
                        Kind = VfxManifest.ReverseMap.PerfectBlock,
                        Duration = 0,
                        Position = attackerCharacterRef.Root.Position,
                    })
                end
            end
            

            continue
        end


        const characterRef = World:get(hit.Target, Components.CharacterRef)
        const health = World:get(hit.Target, Components.Health)
        if health then
            health.Current -= frameData.Damage
            health.Current = math.max(0, health.Current)
            
            if characterRef then
                characterRef.Humanoid.Health = health.Current
            end

            if health.Current <= 0 then
                World:add(hit.Target, Components.Dead)
            end

        end
        
        -- check for existing stun, use highest EndsAt time
        const stunned = World:get(hit.Target, Components.Stunned)
        if stunned then
            stunned.EndsAt = math.max(tick + frameData.Hitstun + frameData.Hitstop, stunned.EndsAt)
        else
            const newStun: Components.Stunned = {
                StartedAt = tick,
                EndsAt = tick + frameData.Hitstun + frameData.Hitstop,
                Source = hit.Attacker,
                Reaction = frameData.Reaction
            }
            World:set(hit.Target, Components.Stunned, newStun)
        end

        if characterRef then
            Packets.Vfx.sendToAll({Character = characterRef.Model, Kind = VfxManifest.ReverseMap.Hit, Duration = 0, Position = characterRef.Root.Position})
        end

        World:remove(hit.Target, Components.ActiveAttack)
        World:remove(hit.Target, Components.ActionLock)

        const targetHitstop = World:get(hit.Target, Components.Hitstop)
        if targetHitstop then
            targetHitstop.EndsAt = math.max(tick + frameData.Hitstop, targetHitstop.EndsAt)
        else
            World:set(hit.Target, Components.Hitstop, {
                EndsAt = tick + frameData.Hitstop,
            })
        end

        const attackerHitstop = World:get(hit.Attacker, Components.Hitstop)

        -- these calculations are for when we hit multiple targets in the same hitbox on different ticks
        -- We cannot simply add Hitstop each to the attacker each time.
        -- If hitstop = 30, and I hit two people on consecutive, they will be paused for 60 ticks
        -- When in reality they should be paused for 31 ticks since the last one came 1 tick after
        const currentFreezeEnd = attackerHitstop and math.max(attackerHitstop.EndsAt, tick) or tick
        local newEnd
        local added

        if attackerHitstop then
            newEnd = math.max(tick + frameData.Hitstop, currentFreezeEnd)
            added = newEnd - currentFreezeEnd

            attackerHitstop.EndsAt = newEnd
        else
            newEnd = tick + frameData.Hitstop
            added = frameData.Hitstop

            World:set(hit.Attacker, Components.Hitstop, {
                EndsAt = newEnd
            })
        end

        const activeAttack = World:get(hit.Attacker, Components.ActiveAttack)
        if activeAttack then
            activeAttack.PausedTicks += added
        end

        const actionLock = World:get(hit.Attacker, Components.ActionLock)
        if actionLock then
            actionLock.EndsAt += added
        end

        const jumpLockout = World:get(hit.Attacker, Components.JumpLockout)
        if jumpLockout then
            jumpLockout.EndsAt += added
        end

        const comboCounter = World:get(hit.Attacker, Components.ComboCounter)
        if comboCounter then
            if comboCounter.Target ~= hit.Target then
                comboCounter.Hits = 1
            else
                comboCounter.Hits += 1
            end
            -- bit longer than combo window
            comboCounter.DecaysAt = tick + frameData.ComboWindow + COMBO_COUNTER_DECAY_OFFSET
            comboCounter.Target = hit.Target
            
        else
            const newComboCounter: Components.ComboCounter = {
                Hits = 1,
                DecaysAt = tick + frameData.ComboWindow + COMBO_COUNTER_DECAY_OFFSET,
                Target = hit.Target
            }
            World:set(hit.Attacker, Components.ComboCounter, newComboCounter)
        end

        -- The slam is what ends the float, and this must run before the branches
        -- below: the knockback branch skips suspended targets, so removing Suspended
        -- here is exactly what lets the downward spike through. Removing it also
        -- fires SuspendAttachmentService's teardown, restoring network ownership
        -- before the Knockback packet goes out.
        if frameData.EndsSuspend then
            World:remove(hit.Target, Components.Suspended)
            World:remove(hit.Attacker, Components.Suspending)
        end

        local shouldHold = false
        const isDead = World:has(hit.Target, Components.Dead)
        const isHolding = World:has(hit.Attacker, Components.Holding)
        const isGrabbed = World:has(hit.Target, Components.Grabbed)
        if frameData.ReleaseTick and activeAttack and not isDead and not isHolding and not isGrabbed then
            shouldHold = true
        end

        if shouldHold and frameData.ReleaseTick and activeAttack then
            const releasesAt = activeAttack.StartedAt + frameData.ReleaseTick + activeAttack.PausedTicks

            const grabbed: Components.Grabbed = {
                Holder = hit.Attacker,
                Ability = hit.Ability,
                HitIndex = hit.HitIndex,
                ReleasesAt = releasesAt,
            }
            World:set(hit.Target, Components.Grabbed, grabbed)

            const holding: Components.Holding = {
                Victim = hit.Target
            }
            World:set(hit.Attacker, Components.Holding, holding)

            const endsAt = releasesAt + math.max(frameData.KnockbackDuration, Ragdoll.MinDuration)
            const thrown: Components.Thrown = {
                EndsAt = endsAt,
                MaxEndsAt = endsAt + THROW_MAX_PAD 
            }
            World:set(hit.Target, Components.Thrown, thrown)
        elseif frameData.SuspendTicks and characterRef then
            -- A suspend owns both characters' positions outright, so it deliberately
            -- writes no Knockback: an impulse on a constrained assembly fights the
            -- constraint it is about to be given.
            const attackerCharacterRef = World:get(hit.Attacker, Components.CharacterRef)
            const ignore = { characterRef.Model } :: { Instance }
            if attackerCharacterRef then
                table.insert(ignore, attackerCharacterRef.Model)
            end

            const travel = Vector3.yAxis * Suspend.Height
            local height = Headroom.Resolve(characterRef.Root.Position, Suspend.CastSize, travel, Suspend.CeilingMargin, ignore)

            -- Both rise to the same height, so the lower of the two ceilings wins.
            -- Otherwise a beam over only one of them splits the pair apart.
            if attackerCharacterRef then
                const attackerHeight = Headroom.Resolve(attackerCharacterRef.Root.Position, Suspend.CastSize, travel, Suspend.CeilingMargin, ignore)
                height = math.min(height, attackerHeight)
            end

            const riseEndsAt = tick + Suspend.RiseTicks
            const endsAt = riseEndsAt + frameData.SuspendTicks

            -- The attacker is the anchor: they rise straight up, and the victim is placed
            -- relative to them. Anchoring on the victim instead would let the pair drift
            -- apart by however far the attacker happened to be standing when it landed.
            local victimGoal = characterRef.Root.Position + Vector3.yAxis * height

            if attackerCharacterRef then
                const attackerGoal = attackerCharacterRef.Root.Position + Vector3.yAxis * height

                const toVictim = characterRef.Root.Position - attackerCharacterRef.Root.Position
                const flat = Vector3.new(toVictim.X, 0, toVictim.Z)
                const facing = if flat.Magnitude > 0.001
                    then flat.Unit
                    else attackerCharacterRef.Root.CFrame.LookVector

                -- The slot in front of the attacker may be inside a wall, so cast out to
                -- it and take whatever fits.
                const slotTravel = facing * Suspend.VictimDistance
                const slotDistance = Headroom.Resolve(attackerGoal, Suspend.CastSize, slotTravel, Suspend.CeilingMargin, ignore)
                victimGoal = attackerGoal + facing * slotDistance

                const suspending: Components.Suspending = {
                    StartedAt = tick,
                    RiseEndsAt = riseEndsAt,
                    EndsAt = endsAt,
                    Origin = attackerCharacterRef.Root.Position,
                    Goal = attackerGoal,
                    Victim = hit.Target,
                }
                World:set(hit.Attacker, Components.Suspending, suspending)
            end

            const suspended: Components.Suspended = {
                StartedAt = tick,
                RiseEndsAt = riseEndsAt,
                EndsAt = endsAt,
                Origin = characterRef.Root.Position,
                Goal = victimGoal,
                Holder = hit.Attacker,
            }
            World:set(hit.Target, Components.Suspended, suspended)

        else
            const attackerCharacterRef = World:get(hit.Attacker, Components.CharacterRef)
            if attackerCharacterRef then
                const lookVector = attackerCharacterRef.Root.CFrame.LookVector
                const knockbackVelocity = lookVector * frameData.KnockbackSpeed + frameData.KnockbackUpward * Vector3.yAxis
                const newKnockback: Components.Knockback = {
                    Velocity = knockbackVelocity,
                    StartedAt = tick,
                    EndsAt = tick + frameData.KnockbackDuration,
                }
    
                if frameData.Ragdoll then
                    const endsAt = tick + math.max(frameData.KnockbackDuration, Ragdoll.MinDuration)
                    const thrown: Components.Thrown = {
                        EndsAt = endsAt,
                        MaxEndsAt = endsAt + THROW_MAX_PAD
                    }
                    World:set(hit.Target, Components.Thrown, thrown)

                    const targetCharacterRef = World:get(hit.Target, Components.CharacterRef)
                    const ragdolled: Components.Ragdolled = {
                        Facing = if targetCharacterRef then targetCharacterRef.Root.CFrame.LookVector else Vector3.zAxis,
                    }
                    World:set(hit.Target, Components.Ragdolled, ragdolled)

                    if frameData.PinTicks then
                        const pending: Components.GroundPinPending = {
                            PinTicks = frameData.PinTicks,
                            EndsAt = tick + Ragdoll.PinGiveUp,
                        }
                        World:set(hit.Target, Components.GroundPinPending, pending)
                    end
                end

                -- A suspended victim's position is owned by their AlignPosition. An
                -- impulse here would shove them out of the float and the next hit of
                -- the air string would whiff.
                if not World:has(hit.Target, Components.Suspended) then
                    World:set(hit.Target, Components.Knockback, newKnockback)
                end

                if characterRef and hit.HitIndex == Abilities.Length(hit.Ability) then
                    Packets.Vfx.sendToAll({Character = characterRef.Model, Kind = VfxManifest.ReverseMap.Knockback, Duration = frameData.KnockbackDuration})
                end
            end
        end
        
    end
end

return HitApplicationSystem
