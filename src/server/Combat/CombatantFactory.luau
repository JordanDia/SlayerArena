--!strict
const PhysicsService = game:GetService("PhysicsService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerStorage = game:GetService("ServerStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const AnimationManifest = require(ReplicatedStorage.Shared.Combat.Data.AnimationManifest)
const EntityRegistry = require(ReplicatedStorage.Shared.Combat.EntityRegistry)
const World = require(ReplicatedStorage.Shared.Combat.World)

const CombatantFactory = {}

local animations: Folder
const byId: { [string]: { Id: string, Looped: boolean, Priority: Enum.AnimationPriority }} = {}

-- So dummy service can override its values

export type Stats = {
    read Health: number,
    read Stamina: number,
    read Posture: number,
    read AirJumps: number,
    read StaminaRegenPerTick: number,
}

export type StatOverrides = {
    Health: number?,
    Stamina: number?,
    Posture: number?,
    AirJumps: number?,
    StaminaRegenPerTick: number?,
}

const DEFAULT_STATS: Stats = table.freeze {
    Health = 100,
    Stamina = 100,
    Posture = 50,
    AirJumps = 1,
    StaminaRegenPerTick = 2/60
}

function CombatantFactory.Init()
    animations = Instance.new("Folder")
    animations.Name = "Animations"
    animations.Parent = ServerStorage

    for _, entry in AnimationManifest do
        const animation = Instance.new("Animation")
        animation.Name = entry.Id
        animation.AnimationId = entry.Id
        byId[entry.Id] = entry

        animation.Parent = animations
    end

    if not PhysicsService:IsCollisionGroupRegistered("Combatant") then
        PhysicsService:RegisterCollisionGroup("Combatant")
    end
end

local function LoadAnimationTracks(humanoid: Humanoid): { [string]: AnimationTrack }?
    const animator = humanoid:WaitForChild("Animator", 10) :: Animator?
    if not animator then return nil end

    const animationTracks: { [string]: AnimationTrack } = {}
    for _, animation in animations:GetChildren() do
        if not animation:IsA("Animation") then continue end
        
        const track = animator:LoadAnimation(animation)
        const entry = byId[animation.AnimationId]
        track.Looped = entry.Looped
        track.Priority = entry.Priority
        animationTracks[animation.AnimationId] = track

        track:Play()
    end

    for _, track in animator:GetPlayingAnimationTracks() do
        track:Stop()
    end

    return animationTracks
end

local function ResolveStats(overrides: StatOverrides?): Stats
    if not overrides then
        return DEFAULT_STATS
    end

    return {
        Health = overrides.Health or DEFAULT_STATS.Health,
        Stamina = overrides.Stamina or DEFAULT_STATS.Stamina,
        Posture = overrides.Posture or DEFAULT_STATS.Posture,
        AirJumps = overrides.AirJumps or DEFAULT_STATS.AirJumps,
        StaminaRegenPerTick = overrides.StaminaRegenPerTick or DEFAULT_STATS.StaminaRegenPerTick,
    }
end

function CombatantFactory.Create(character: Model, overrides: StatOverrides?): World.Entity?
    if EntityRegistry.Get(character) then return nil end

    const humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
    const root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
    if not humanoid or not root then return nil end

    if not animations then
        warn("ServerStorage.Animations not loaded yet!")
        return nil
    end

    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)

    const animationTracks = LoadAnimationTracks(humanoid)
    if not animationTracks then return nil end

    -- check again, character could've got binded during WaitForChild yield
    if EntityRegistry.Get(character) then return nil end

    const entity = World:entity()
    World:set(entity, Components.AnimationTracks, animationTracks)

    World:set(entity, Components.CharacterRef, {
        Model = character,
        Humanoid = humanoid,
        Root = root,
    })

    const entityStats = ResolveStats(overrides)
    
    World:set(entity, Components.Health, { Current = entityStats.Health, Max = entityStats.Health })
    World:set(entity, Components.Stamina, { Current = entityStats.Stamina, Max = entityStats.Stamina, RegenPerTick = entityStats.StaminaRegenPerTick })
    World:set(entity, Components.Posture, { Current = entityStats.Posture, Max = entityStats.Posture, LastDamagedTick = 0 })
    World:set(entity, Components.AirJumps, { Used = 0, Max = entityStats.AirJumps} )

    const cooldowns: Components.Cooldowns = {}
    World:set(entity, Components.Cooldowns, cooldowns)

    EntityRegistry.Register(character, entity)
    print(`{ character.Name } has entity id: { entity }`)

    for _, part in character:GetDescendants() do
        if not part:IsA("BasePart") then continue end
        part.CollisionGroup = "Combatant"
    end

    return entity
end

return CombatantFactory