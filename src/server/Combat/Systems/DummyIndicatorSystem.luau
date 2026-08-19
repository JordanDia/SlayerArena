--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function DummyIndicatorSystem(tick: number, _delta: number)
    for entity, dummy, _characterRef in World:query(Components.Dummy, Components.CharacterRef):without(Components.Dead) do
        const stunned = World:has(entity, Components.Stunned)
        const blocking = World:has(entity, Components.Blocking)

        if stunned then
            if dummy.Indicator.BrickColor ~= BrickColor.Red() then
                dummy.Indicator.BrickColor = BrickColor.Red()
            end

        elseif blocking then
            if dummy.Indicator.BrickColor ~= BrickColor.Blue() then
                dummy.Indicator.BrickColor = BrickColor.Blue()
            end
        else
            if dummy.Indicator.BrickColor ~= BrickColor.Green() then
                dummy.Indicator.BrickColor = BrickColor.Green()
            end
        end
    end
end

return DummyIndicatorSystem
