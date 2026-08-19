--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Abilities = require(ReplicatedStorage.Shared.Combat.Data.Abilities)
const Components = require("../Components")
const EntityRegistry = require("../EntityRegistry")
const HitQueue = require("../HitQueue")
const World = require("../World")

const overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude
overlapParams.MaxParts = 20

const function HitDetectionSystem(tick: number, _delta: number)
    for entity, activeAttack, characterRef in World:query(Components.ActiveAttack, Components.CharacterRef):without(Components.Dead) do
        const frameData = Abilities.Get(activeAttack.Ability, activeAttack.HitIndex)
        const activeStart = activeAttack.StartedAt + frameData.Startup + activeAttack.PausedTicks
        const activeEnd = activeStart + frameData.Active

        if tick < activeStart or tick >= activeEnd then continue end

        const rootCFrame = characterRef.Root.CFrame
        const center = rootCFrame.Position + rootCFrame.LookVector * frameData.Range

        overlapParams.FilterDescendantsInstances = { characterRef.Model }
        const parts = workspace:GetPartBoundsInRadius(center, frameData.Radius, overlapParams)

        for _, part in parts do
            const model = part:FindFirstAncestorOfClass("Model")
            if not model then continue end

            const target = EntityRegistry.Get(model)
            if not target then continue end

            if target == entity then continue end
            if activeAttack.HasHit[target] then continue end
            if World:has(target, Components.Dead) then continue end

            activeAttack.HasHit[target] = true
            const pendingHit: HitQueue.PendingHit = {
                Attacker = entity,
                Target = target,
                Ability = activeAttack.Ability,
                HitIndex = activeAttack.HitIndex,
                Tick = tick,
                Position = part.Position
            }

            HitQueue.Push(pendingHit)
        end
    end
end

return HitDetectionSystem