--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Suspend = require(ReplicatedStorage.Shared.Combat.Data.Suspend)
const Components = require("../Components")
const World = require("../World")

const ALIGN_POSITION_NAME = "SuspendAlign"

const function SuspendSystem(tick: number, _delta: number)
    for _entity, suspended, characterRef in World:query(Components.Suspended, Components.CharacterRef):without(Components.Dead) do
        const alignPosition = characterRef.Root:FindFirstChild(ALIGN_POSITION_NAME)
        if not alignPosition or not alignPosition:IsA("AlignPosition") then continue end

        const alpha = math.clamp((tick - suspended.StartedAt) / Suspend.RiseTicks, 0, 1)

        -- Smoothstep. The rise curve is authored here, in ticks, rather than left to the
        -- constraint's spring - spring settling time is not tick quantised and would drift
        -- out of step with the frame data.
        const eased = alpha * alpha * (3 - 2 * alpha)

        -- Computed from the stored origin and goal, never from the root's current
        -- position: the constraint is driving that position, so integrating from it
        -- would feed the constraint its own output.
        alignPosition.Position = suspended.Origin:Lerp(suspended.Goal, eased)
    end

    for _entity, suspending, characterRef in World:query(Components.Suspending, Components.CharacterRef):without(Components.Dead) do
        const alignPosition = characterRef.Root:FindFirstChild(ALIGN_POSITION_NAME)
        if not alignPosition or not alignPosition:IsA("AlignPosition") then continue end

        const alpha = math.clamp((tick - suspending.StartedAt) / Suspend.RiseTicks, 0, 1)
        const eased = alpha * alpha * (3 - 2 * alpha)

        -- One lerp of a Vector3, not just Y: the attacker travels up and sideways at
        -- once, arriving in the slot on the same tick the victim reaches the apex.
        alignPosition.Position = suspending.Origin:Lerp(suspending.Goal, eased)
    end
end

return SuspendSystem
