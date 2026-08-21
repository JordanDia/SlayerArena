--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Abilities = require(ReplicatedStorage.Shared.Combat.Data.Abilities)
const Components = require("../Components")
const EntityRegistry = require("../EntityRegistry")
const HitQueue = require("../HitQueue")
const World = require("../World")

const RunService = game:GetService("RunService")

const SHOW_HITBOXES = true
const HITBOX_DEBUG_LIFETIME = 0.3

const overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude
overlapParams.MaxParts = 20

local function DrawHitbox(cframe: CFrame, size: Vector3)
    const part = Instance.new("Part")
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.Color = Color3.fromRGB(255, 0, 0)
    part.Material = Enum.Material.Neon
    part.Transparency = 0.7
    part.Name = "HitboxDebug"
    part.Parent = workspace

    task.delay(HITBOX_DEBUG_LIFETIME, function()
        part:Destroy()
    end)
end

const function HitDetectionSystem(tick: number, _delta: number)
    for entity, activeAttack, characterRef in World:query(Components.ActiveAttack, Components.CharacterRef):without(Components.Dead) do
        const frameData = Abilities.Get(activeAttack.Ability, activeAttack.HitIndex)
        const activeStart = activeAttack.StartedAt + frameData.Startup + activeAttack.PausedTicks
        const activeEnd = activeStart + frameData.Active

        if tick < activeStart or tick >= activeEnd then continue end

        const rootCFrame = characterRef.Root.CFrame
        const hitboxCFrame = rootCFrame * CFrame.new(0, 0, -frameData.Range)

        if SHOW_HITBOXES and RunService:IsStudio() then
            DrawHitbox(hitboxCFrame, frameData.HitboxSize)
        end

        overlapParams.FilterDescendantsInstances = { characterRef.Model }
        const parts = workspace:GetPartBoundsInBox(hitboxCFrame, frameData.HitboxSize, overlapParams)

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