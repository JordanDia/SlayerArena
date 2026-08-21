--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const World = require(ReplicatedStorage.Shared.Combat.World)

const BASE_WALK_SPEED = 16
const BASE_JUMP_HEIGHT = 7.2
const ATTACK_WALK_SPEED_CONSTANT = 8
const DASH_MASK = 3

const function MovementLockSystem(tick: number, _delta: number)
    for entity, characterRef in World:query(Components.CharacterRef):without(Components.Dead) do
        const hitstop = World:has(entity, Components.Hitstop)
        const stunned = World:has(entity, Components.Stunned)
        const blockstun = World:has(entity, Components.Blockstun)
        const holding = World:has(entity, Components.Holding)
        const blocking = World:has(entity, Components.Blocking)
        const actionLock = World:has(entity, Components.ActionLock)

        local desiredWalkSpeed = BASE_WALK_SPEED
        local desiredJumpHeight = (stunned or actionLock) and 0 or BASE_JUMP_HEIGHT
        
        if hitstop or stunned or blockstun or holding then
            desiredWalkSpeed = 0
            desiredJumpHeight = 0
        elseif blocking then
            desiredWalkSpeed = 6
            desiredJumpHeight = 0
        elseif actionLock then
            const lock = World:get(entity, Components.ActionLock)
            if lock and (lock.Mask == 2 or lock.Mask == DASH_MASK) then
                desiredWalkSpeed = 0
            else
                desiredWalkSpeed = ATTACK_WALK_SPEED_CONSTANT
            end
        end
    
        if characterRef.Humanoid.WalkSpeed ~= desiredWalkSpeed then
            characterRef.Humanoid.WalkSpeed = desiredWalkSpeed
        end

        if characterRef.Humanoid.JumpHeight ~= desiredJumpHeight then
            characterRef.Humanoid.JumpHeight = desiredJumpHeight
        end
    end
end

return MovementLockSystem