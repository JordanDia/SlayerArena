--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Abilities = require(ReplicatedStorage.Shared.Combat.Data.Abilities)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function AttackAnimationSystem(tick: number, _delta: number)
    for _entity, activeAttack, animationTracks in World:query(Components.ActiveAttack, Components.AnimationTracks):without(Components.Dead) do
        const frameData = Abilities.Get(activeAttack.Ability, activeAttack.HitIndex)


        if activeAttack.StartedAt == tick then
            const animationId = frameData.AnimationId
            const track = animationTracks[animationId]

            if track then
                track:Play(0.1)
            end
        end

        if not frameData.LoopAnimationId then continue end

        const loopTrack = animationTracks[frameData.LoopAnimationId]
        if not loopTrack then continue end

        const elapsed = tick - activeAttack.StartedAt - activeAttack.PausedTicks
        if elapsed == frameData.Startup then
            loopTrack:Play(0.15)
        elseif elapsed == frameData.Startup + frameData.Active then
            loopTrack:Stop(0.2)
        end
    end
    
end

return AttackAnimationSystem
