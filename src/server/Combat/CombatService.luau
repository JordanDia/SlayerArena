--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Scheduler = require(ReplicatedStorage.Shared.Combat.Scheduler)
const Pipeline = require(ReplicatedStorage.Shared.Combat.Pipeline)

const CharacterBindingService = require("./CharacterBindingService")

const SharedSystems = ReplicatedStorage.Shared.Combat.Systems
const ServerSystems = script.Parent.Systems

const StaminaRegenSystem: Pipeline.System = require(SharedSystems.StaminaRegenSystem)
const PostureSystem: Pipeline.System = require(SharedSystems.PostureSystem)
const ExpirySystem: Pipeline.System = require(SharedSystems.ExpirySystem)
const AttackSystem: Pipeline.System = require(SharedSystems.AttackSystem)
const BlockSystem: Pipeline.System = require(SharedSystems.BlockSystem)
const DodgeSystem: Pipeline.System = require(SharedSystems.DodgeSystem)
const AttackAnimationSystem: Pipeline.System = require(ServerSystems.AttackAnimationSystem)
const AttackVfxSystem: Pipeline.System = require(ServerSystems.AttackVfxSystem)
const HitDetectionSystem: Pipeline.System = require(SharedSystems.HitDetectionSystem)
const HitApplicationSystem: Pipeline.System = require(SharedSystems.HitApplicationSystem)
const GrabReleaseSystem: Pipeline.System = require(SharedSystems.GrabReleaseSystem)
const HitReactionAnimationSystem: Pipeline.System = require(ServerSystems.HitReactionAnimationSystem)
const KnockbackReplicationSystem: Pipeline.System = require(ServerSystems.KnockbackReplicationSystem)
const NpcKnockbackSystem: Pipeline.System = require(ServerSystems.NpcKnockbackSystem)
const MovementLockSystem: Pipeline.System = require(ServerSystems.MovementLockSystem)
const HitstopAnimationSystem: Pipeline.System = require(ServerSystems.HitstopAnimationSystem)
const DummyIndicatorSystem: Pipeline.System = require(ServerSystems.DummyIndicatorSystem)
const DummyBehaviorSystem: Pipeline.System = require(ServerSystems.DummyBehaviorSystem)
const RagdollSystem: Pipeline.System = require(SharedSystems.RagdollSystem)

local pipeline: Pipeline.Pipeline? = nil

const CombatService = {}

function CombatService:Init()
    pipeline = Pipeline.new()

    -- Pipeline order:
    -- Expiry,
    -- Attack,
    -- Hit Detection, Hit Application,
    -- Knockback / movement,
    -- Stamina Regen
    -- Reap

    pipeline:Add("Expiry", ExpirySystem)
    pipeline:Add("Ragdoll", RagdollSystem)
    pipeline:Add("DummyBehaviorSystem", DummyBehaviorSystem)
    pipeline:Add("Block", BlockSystem)
    pipeline:Add("Dodge", DodgeSystem)
    pipeline:Add("Attack", AttackSystem)
    pipeline:Add("AttackAnimation", AttackAnimationSystem)
    pipeline:Add("AttackVfx", AttackVfxSystem)
    pipeline:Add("HitDetection", HitDetectionSystem)
    pipeline:Add("HitApplication", HitApplicationSystem)
    pipeline:Add("GrabRelease", GrabReleaseSystem)
    pipeline:Add("HitReactionAnimation", HitReactionAnimationSystem)
    pipeline:Add("HitstopAnimation", HitstopAnimationSystem)
    pipeline:Add("MovementLock", MovementLockSystem)
    pipeline:Add("KnockbackReplication", KnockbackReplicationSystem)
    pipeline:Add("NpcKnockback", NpcKnockbackSystem)
    pipeline:Add("Posture", PostureSystem)
    pipeline:Add("StaminaRegen", StaminaRegenSystem)
    pipeline:Add("DummyIndicator", DummyIndicatorSystem)
    pipeline:Add("Reap", CharacterBindingService.ReapSystem)

    pipeline:Lock()
end

function CombatService:Start()
    if pipeline then
        Scheduler.Start(pipeline:GetRunner())
    end
end

return CombatService