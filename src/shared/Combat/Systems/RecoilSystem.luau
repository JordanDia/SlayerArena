--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Abilities = require(ReplicatedStorage.Shared.Combat.Data.Abilities)
const Components = require("../Components")
const World = require("../World")

const function RecoilSystem(tick: number, _delta: number)
    for entity, activeAttack, characterRef in World:query(Components.ActiveAttack, Components.CharacterRef):without(Components.Dead) do
        if activeAttack.FiredRecoil then continue end

        const frameData = Abilities.Get(activeAttack.Ability, activeAttack.HitIndex)
        if not frameData.RecoilTick then continue end

        const elapsed = tick - activeAttack.StartedAt - activeAttack.PausedTicks
        if elapsed < frameData.RecoilTick then continue end

        activeAttack.FiredRecoil = true

        const look = characterRef.Root.CFrame.LookVector
        const velocity = -look * (frameData.RecoilSpeed or 0) + Vector3.yAxis * (frameData.RecoilUpward or 0)

        const knockback: Components.Knockback = {
            Velocity = velocity,
            StartedAt = tick,
            EndsAt = tick + (frameData.RecoilDuration or 0),
        }
        World:set(entity, Components.Knockback, knockback)
    end
end

return RecoilSystem
