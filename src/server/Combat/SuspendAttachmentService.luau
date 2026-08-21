--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Jecs = require(ReplicatedStorage.Packages.Jecs)
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Suspend = require(ReplicatedStorage.Shared.Combat.Data.Suspend)
const World = require(ReplicatedStorage.Shared.Combat.World)

const ALIGN_POSITION_NAME = "SuspendAlign"
const ALIGN_ORIENTATION_NAME = "SuspendAlignOrientation"
const ATTACHMENT_NAME = "SuspendAnchor"

const SuspendAttachmentService = {}

--[[
    The victim and the attacker get the same AlignPosition rig, but differ in two ways
    that matter:

    `platformStand` - the victim is fully locked, so silencing their Humanoid is free.
    Doing it to the attacker would break their animations and their ability to attack,
    which is the entire point of suspending them. Their WalkSpeed is zeroed by
    MovementLockSystem instead, so there is no drive to fight the constraint with.

    `orient` - the victim is held upright and facing the way they were hit. The attacker
    is left to their camera; forcing their facing would fight AutoRotate every frame for
    no gain, since their camera already points at the character they just launched.
]]
local function Attach(characterRef: Components.CharacterRef, platformStand: boolean, orient: boolean, owner: Player?)
    -- The constraint is simulated by whoever owns the assembly, so the victim is
    -- handed to the attacker's client. Leaving them server-owned puts their rise a
    -- full round trip behind the attacker's, which reads as the pair desyncing.
    -- Same trade GrabAttachmentService makes: the player who is acting sees it
    -- immediately, and the one being acted on absorbs the latency.
    if platformStand then
        if not characterRef.Root:IsGrounded() then
            characterRef.Root:SetNetworkOwner(owner)
        end
        characterRef.Humanoid.PlatformStand = true
    end

    const attachment = Instance.new("Attachment")
    attachment.Name = ATTACHMENT_NAME
    attachment.Parent = characterRef.Root

    const alignPosition = Instance.new("AlignPosition")
    alignPosition.Name = ALIGN_POSITION_NAME
    alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
    alignPosition.Attachment0 = attachment
    alignPosition.Position = characterRef.Root.Position
    alignPosition.MaxForce = Suspend.MaxForce
    alignPosition.Responsiveness = Suspend.Responsiveness
    alignPosition.RigidityEnabled = false
    alignPosition.Parent = characterRef.Root

    if not orient then return end

    const lookVector = characterRef.Root.CFrame.LookVector
    const flat = Vector3.new(lookVector.X, 0, lookVector.Z)

    const alignOrientation = Instance.new("AlignOrientation")
    alignOrientation.Name = ALIGN_ORIENTATION_NAME
    alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOrientation.Attachment0 = attachment
    alignOrientation.CFrame = if flat.Magnitude > 0.001
        then CFrame.lookAt(Vector3.zero, flat.Unit)
        else CFrame.identity
    alignOrientation.MaxTorque = Suspend.MaxForce
    alignOrientation.Responsiveness = Suspend.Responsiveness
    alignOrientation.RigidityEnabled = false
    alignOrientation.Parent = characterRef.Root
end

local function Detach(characterRef: Components.CharacterRef, platformStand: boolean)
    for _, name in { ALIGN_POSITION_NAME, ALIGN_ORIENTATION_NAME, ATTACHMENT_NAME } do
        const instance = characterRef.Root:FindFirstChild(name)
        if instance then
            instance:Destroy()
        end
    end

    if not platformStand then return end

    characterRef.Humanoid.PlatformStand = false

    if not characterRef.Root:IsGrounded() then
        characterRef.Root:SetNetworkOwnershipAuto()
    end
end

function SuspendAttachmentService:Init()

    World:added(Components.Suspended, function(entity: World.Entity, _componentId: Jecs.Id<Components.Suspended>, value: Components.Suspended, _oldarchetype: Jecs.Archetype)
        const characterRef = World:get(entity, Components.CharacterRef)
        if not characterRef then return end

        -- nil when the attacker is an NPC, which leaves the victim server-simulated.
        const holderPlayerRef = World:get(value.Holder, Components.PlayerRef)
        Attach(characterRef, true, true, holderPlayerRef)
    end)

    World:removed(Components.Suspended, function(entity: World.Entity, _componentId: Jecs.Id<Components.Suspended>, isDeleting: boolean?)
        if isDeleting then return end

        const characterRef = World:get(entity, Components.CharacterRef)
        if not characterRef then return end

        Detach(characterRef, true)
    end)

    World:added(Components.Suspending, function(entity: World.Entity, _componentId: Jecs.Id<Components.Suspending>, _value: Components.Suspending, _oldarchetype: Jecs.Archetype)
        const characterRef = World:get(entity, Components.CharacterRef)
        if not characterRef then return end

        Attach(characterRef, false, false, nil)
    end)

    World:removed(Components.Suspending, function(entity: World.Entity, _componentId: Jecs.Id<Components.Suspending>, isDeleting: boolean?)
        if isDeleting then return end

        const characterRef = World:get(entity, Components.CharacterRef)
        if not characterRef then return end

        Detach(characterRef, false)
    end)

end

return SuspendAttachmentService
