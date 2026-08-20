--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Abilities = require(ReplicatedStorage.Shared.Combat.Data.Abilities)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function AttackAnimationSystem(tick: number, _delta: number)
    for _entity, activeAttack, animationTracks in World:query(Components.ActiveAttack, Components.AnimationTracks):without(Components.Dead) do
        
        if activeAttack.StartedAt == tick then
            const animationId = Abilities.Get(activeAttack.Ability, activeAttack.HitIndex).AnimationId
            const track = animationTracks[animationId]
            if not track then continue end

            track:Play(0.1)
        end
    end
    
end

return AttackAnimationSystem
