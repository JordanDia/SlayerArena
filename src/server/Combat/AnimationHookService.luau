--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Jecs = require(ReplicatedStorage.Packages.Jecs)
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Dodge = require(ReplicatedStorage.Shared.Combat.Data.Dodge)
const M1 = require(ReplicatedStorage.Shared.Combat.Data.M1)
const States = require(ReplicatedStorage.Shared.Combat.Data.States)
const World = require(ReplicatedStorage.Shared.Combat.World)

const AnimationHookService = {}

function AnimationHookService:Init()
    World:removed(Components.ActiveAttack, function(entity: World.Entity, _componentId: Jecs.Id<Components.ActiveAttack>, isDeleting: boolean?)
        if isDeleting then return end
        const tracks = World:get(entity, Components.AnimationTracks)
        if not tracks then return end

        for _, frameData in M1 do
            const track = tracks[frameData.AnimationId]
            if not track then continue end

            track:Stop(0.06)
        end
    end)

    World:removed(Components.Hitstop, function(entity: World.Entity, _componentId: Jecs.Id<Components.Hitstop>, isDeleting: boolean?)
        if isDeleting then return end

        const hitstop = World:get(entity, Components.Hitstop)
        if hitstop and hitstop.Frozen then
            for track, speed in hitstop.Frozen do
                track:AdjustSpeed(speed)
            end
        end
    end)

    World:added(Components.Blocking, function(entity: World.Entity, _componentId: Jecs.Id<Components.Blocking>, _value: Components.Blocking, _oldarchetype: Jecs.Archetype)
        const animationTracks = World:get(entity, Components.AnimationTracks)
        if animationTracks then
            const track = animationTracks[States.Block.Id]
            track:Play(0.1)
        end
    end)

    World:removed(Components.Blocking, function(entity: World.Entity, _componentId: Jecs.Id<Components.Blocking>, isDeleting: boolean?)
        if isDeleting then return end

        const animationTracks = World:get(entity, Components.AnimationTracks)
        if animationTracks then
            const track = animationTracks[States.Block.Id]
            track:Stop(0.1)
        end
    end)

    World:added(Components.Invulnerable, function(entity: World.Entity, _componentId: Jecs.Id<Components.Invulnerable>, _value: Components.Invulnerable, _oldarchetype: Jecs.Archetype)
        const animationTracks = World:get(entity, Components.AnimationTracks)
        if animationTracks then
            const track = animationTracks[Dodge.AnimationId]
            track:Play(0.05)
        end
    end)
end

return AnimationHookService