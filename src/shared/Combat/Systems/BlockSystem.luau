--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Block = require(ReplicatedStorage.Shared.Combat.Data.Block)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function BlockSystem(tick: number, _delta: number)
    for entity, blockHeld in World:query(Components.BlockHeld):without(Components.Dead) do

        const blocking = World:has(entity, Components.Blocking)
        const stunned = World:has(entity, Components.Stunned)
        const activeAttack = World:has(entity, Components.ActiveAttack)
        const actionLocked = World:has(entity, Components.ActionLock)
        const blockstun = World:has(entity, Components.Blockstun)

        local enoughPosture = false
        const posture = World:get(entity, Components.Posture)
        if posture then
            enoughPosture = posture.Current >= Block.MinPostureToBlock
        end
        
        if blockHeld.Wants then
            if blocking or stunned or activeAttack or actionLocked or (not enoughPosture) then
                continue
            end

            World:set(entity, Components.Blocking, { Since = tick })

        else
            if not blocking or blockstun then continue end

            World:remove(entity, Components.Blocking)

            const actionLock = World:get(entity, Components.ActionLock)
            if actionLock then
                actionLock.EndsAt = math.max(tick + Block.ReleaseLag, actionLock.EndsAt)
                actionLock.Mask = 1
            else
                World:set(entity, Components.ActionLock, {
                    EndsAt = tick + Block.ReleaseLag,
                    Mask = 1
                })
            end
        end
        
    end

end

return BlockSystem
