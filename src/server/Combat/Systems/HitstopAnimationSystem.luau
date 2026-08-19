--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function HitstopAnimationSystem(tick: number, _delta: number)
    for _entity, hitstop, animationTracks in World:query(Components.Hitstop, Components.AnimationTracks):without(Components.Dead) do
        if not hitstop.Frozen then
            const frozen: { [AnimationTrack]: number } = {}
            for _, track in animationTracks do
                if not track.IsPlaying then continue end
                frozen[track] = track.Speed
                track:AdjustSpeed(0)
            end
            hitstop.Frozen = frozen
        end
    end

end

return HitstopAnimationSystem
