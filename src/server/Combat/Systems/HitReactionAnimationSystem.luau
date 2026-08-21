const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Reactions = require(ReplicatedStorage.Shared.Combat.Data.Reactions)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function HitReactionAnimationSystem(tick: number, _delta: number)
    for _entity, stunned, animationTracks in World:query(Components.Stunned, Components.AnimationTracks):without(Components.Dead) do
        if stunned.StartedAt < tick then continue end

        const reaction = Reactions[stunned.Reaction]
        const track = animationTracks[reaction.Id]

        if not track then continue end
        track:Play(0.08)
    end
end

return HitReactionAnimationSystem