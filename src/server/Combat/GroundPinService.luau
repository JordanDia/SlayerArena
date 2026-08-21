--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Jecs = require(ReplicatedStorage.Packages.Jecs)
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Ragdoll = require(ReplicatedStorage.Shared.Combat.Data.Ragdoll)
const World = require(ReplicatedStorage.Shared.Combat.World)

const ALIGN_POSITION_NAME = "GroundPinAlign"
const ATTACHMENT_NAME = "GroundPinAnchor"

const GroundPinService = {}

function GroundPinService:Init()

    World:added(Components.GroundPinned, function(entity: World.Entity, _componentId: Jecs.Id<Components.GroundPinned>, value: Components.GroundPinned, _oldarchetype: Jecs.Archetype)
        const characterRef = World:get(entity, Components.CharacterRef)
        if not characterRef then return end

        const attachment = Instance.new("Attachment")
        attachment.Name = ATTACHMENT_NAME
        attachment.Parent = characterRef.Root

        -- Position only, no AlignOrientation: the root is held where it landed while the
        -- limbs stay free to settle, which is what keeps it reading as a ragdoll rather
        -- than a frozen statue.
        const alignPosition = Instance.new("AlignPosition")
        alignPosition.Name = ALIGN_POSITION_NAME
        alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
        alignPosition.Attachment0 = attachment
        alignPosition.Position = value.Position
        alignPosition.MaxForce = Ragdoll.PinMaxForce
        alignPosition.Responsiveness = Ragdoll.PinResponsiveness
        alignPosition.RigidityEnabled = false
        alignPosition.Parent = characterRef.Root
    end)

    World:removed(Components.GroundPinned, function(entity: World.Entity, _componentId: Jecs.Id<Components.GroundPinned>, isDeleting: boolean?)
        if isDeleting then return end

        const characterRef = World:get(entity, Components.CharacterRef)
        if not characterRef then return end

        for _, name in { ALIGN_POSITION_NAME, ATTACHMENT_NAME } do
            const instance = characterRef.Root:FindFirstChild(name)
            if instance then
                instance:Destroy()
            end
        end
    end)

end

return GroundPinService
