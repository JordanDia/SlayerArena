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
const DashSystem: Pipeline.System = require(SharedSystems.DashSystem)
const DoubleJumpSystem: Pipeline.System = require(SharedSystems.DoubleJumpSystem)
const AttackAnimationSystem: Pipeline.System = require(ServerSystems.AttackAnimationSystem)
const AttackVfxSystem: Pipeline.System = require(ServerSystems.AttackVfxSystem)
const ChargeSystem: Pipeline.System = require(ServerSystems.ChargeSystem)
const AttackSoundSystem: Pipeline.System = require(ServerSystems.AttackSoundSystem)
const HitDetectionSystem: Pipeline.System = require(SharedSystems.HitDetectionSystem)
const HitApplicationSystem: Pipeline.System = require(SharedSystems.HitApplicationSystem)
const RecoilSystem: Pipeline.System = require(SharedSystems.RecoilSystem)
const GrabReleaseSystem: Pipeline.System = require(SharedSystems.GrabReleaseSystem)
const SuspendSystem: Pipeline.System = require(SharedSystems.SuspendSystem)
const GroundPinSystem: Pipeline.System = require(SharedSystems.GroundPinSystem)
const HitReactionAnimationSystem: Pipeline.System = require(ServerSystems.HitReactionAnimationSystem)
const KnockbackReplicationSystem: Pipeline.System = require(ServerSystems.KnockbackReplicationSystem)
const NpcKnockbackSystem: Pipeline.System = require(ServerSystems.NpcKnockbackSystem)
const NpcDashSystem: Pipeline.System = require(ServerSystems.NpcDashSystem)
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
    pipeline:Add("Dash", DashSystem)
    pipeline:Add("DoubleJump", DoubleJumpSystem)
    pipeline:Add("Attack", AttackSystem)
    pipeline:Add("Charge", ChargeSystem)
    pipeline:Add("AttackAnimation", AttackAnimationSystem)
    pipeline:Add("AttackVfx", AttackVfxSystem)
    pipeline:Add("AttackSound", AttackSoundSystem)
    pipeline:Add("Recoil", RecoilSystem)
    pipeline:Add("HitDetection", HitDetectionSystem)
    pipeline:Add("HitApplication", HitApplicationSystem)
    pipeline:Add("GrabRelease", GrabReleaseSystem)
    pipeline:Add("Suspend", SuspendSystem)
    pipeline:Add("GroundPin", GroundPinSystem)
    pipeline:Add("HitReactionAnimation", HitReactionAnimationSystem)
    pipeline:Add("HitstopAnimation", HitstopAnimationSystem)
    pipeline:Add("MovementLock", MovementLockSystem)
    pipeline:Add("KnockbackReplication", KnockbackReplicationSystem)
    pipeline:Add("NpcKnockback", NpcKnockbackSystem)
    pipeline:Add("NpcDash", NpcDashSystem)
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