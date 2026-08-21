--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Jecs = require(ReplicatedStorage.Packages.Jecs)
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Dash = require(ReplicatedStorage.Shared.Combat.Data.Dash)
const DoubleJump = require(ReplicatedStorage.Shared.Combat.Data.DoubleJump)
const Dodge = require(ReplicatedStorage.Shared.Combat.Data.Dodge)
const M1 = require(ReplicatedStorage.Shared.Combat.Data.M1)
const Reactions = require(ReplicatedStorage.Shared.Combat.Data.Reactions)
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

    World:removed(Components.Stunned, function(entity: World.Entity, _componentId: Jecs.Id<Components.Stunned>, isDeleting: boolean?)
        if isDeleting then return end

        const animationTracks = World:get(entity, Components.AnimationTracks)
        if not animationTracks then return end

        for _, reaction in Reactions do
            if not reaction.Looped then continue end

            const track = animationTracks[reaction.Id]
            if not track then continue end

            track:Stop(0.1)
        end
    end)

    World:added(Components.Dashing, function(entity: World.Entity, _componentId: Jecs.Id<Components.Dashing>, value: Components.Dashing, _oldarchetype: Jecs.Archetype)
        const animationTracks = World:get(entity, Components.AnimationTracks)
        if not animationTracks then return end

        const track = animationTracks[Dash.AnimationMap[value.Kind]]
        if not track then return end

        track:Play(0.1)
    end)

    World:removed(Components.Dashing, function(entity: World.Entity, _componentId: Jecs.Id<Components.Dashing>, isDeleting: boolean?)
        if isDeleting then return end

        const animationTracks = World:get(entity, Components.AnimationTracks)
        if not animationTracks then return end

        for _, animationId in Dash.AnimationMap do
            const track = animationTracks[animationId]
            if not track then continue end

            track:Stop(0.1)
        end
    end)

    World:added(Components.DoubleJumping, function(entity: World.Entity, _componentId: Jecs.Id<Components.DoubleJumping>, value: Components.DoubleJumping, _oldarchetype: Jecs.Archetype)
        const animationId = DoubleJump.AnimationMap[value.Kind]
        if animationId == "" then return end

        const animationTracks = World:get(entity, Components.AnimationTracks)
        if not animationTracks then return end

        const track = animationTracks[animationId]
        if not track then return end

        track:Play(0.1)
    end)

    World:removed(Components.DoubleJumping, function(entity: World.Entity, _componentId: Jecs.Id<Components.DoubleJumping>, isDeleting: boolean?)
        if isDeleting then return end

        const animationTracks = World:get(entity, Components.AnimationTracks)
        if not animationTracks then return end

        for _, animationId in DoubleJump.AnimationMap do
            if animationId == "" then continue end

            const track = animationTracks[animationId]
            if not track then continue end

            track:Stop(0.1)
        end
    end)

    World:added(Components.Invulnerable, function(entity: World.Entity, _componentId: Jecs.Id<Components.Invulnerable>, value: Components.Invulnerable, _oldarchetype: Jecs.Archetype)
        if value.Kind ~= "Dodge" then return end

        const animationTracks = World:get(entity, Components.AnimationTracks)
        if not animationTracks then return end

        const track = animationTracks[Dodge.AnimationId]
        if not track then return end

        track:Play(0.05)
    end)
end

return AnimationHookService