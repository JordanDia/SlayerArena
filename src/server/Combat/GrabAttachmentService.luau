--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Jecs = require(ReplicatedStorage.Packages.Jecs)
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const World = require(ReplicatedStorage.Shared.Combat.World)

const GrabAttachmentService = {}

function GrabAttachmentService:Init()

    World:added(Components.Grabbed, function(entity: World.Entity, _componentId: Jecs.Id<Components.Grabbed>, value: Components.Grabbed, _oldarchetype: Jecs.Archetype)
        const victimCharacterRef = World:get(entity, Components.CharacterRef)
        const holderCharacterRef = World:get(value.Holder, Components.CharacterRef)
        if not victimCharacterRef or not holderCharacterRef then return end

        const holderRightArm = holderCharacterRef.Model:FindFirstChild("Right Arm") :: BasePart?
        if not holderRightArm then return end

        const victimHead = victimCharacterRef.Model:FindFirstChild("Head") :: BasePart?
        if not victimHead then return end

        const headOffset = victimCharacterRef.Root.CFrame:ToObjectSpace(victimHead.CFrame)

        const holderPlayerRef = World:get(value.Holder, Components.PlayerRef)
        if holderPlayerRef then
            if not victimCharacterRef.Root:IsGrounded() then
                victimCharacterRef.Root:SetNetworkOwner(holderPlayerRef)
            end
        else
            if not victimCharacterRef.Root:IsGrounded() then
                victimCharacterRef.Root:SetNetworkOwner(nil)
            end
        end

        -- restore to 0, if we touch RootPriority as game grows,
        -- we will store initial RootPriority in Grabbed component
        victimCharacterRef.Root.RootPriority = -127

        const motor = Instance.new("Motor6D")
        motor.Name = "GrabHold"
        motor.Part0 = holderRightArm
        motor.Part1 = victimCharacterRef.Root
        motor.C0 = headOffset:Inverse()
        motor.Parent = holderRightArm

        victimCharacterRef.Humanoid.PlatformStand = true

        
    end)

    World:removed(Components.Grabbed, function(entity: World.Entity, _componentId: Jecs.Id<Components.Grabbed>, isDeleting: boolean?)
        if isDeleting then return end

        const grabbed = World:get(entity, Components.Grabbed)
        if grabbed then
            const victimCharacterRef = World:get(entity, Components.CharacterRef)
            const holderCharacterRef = World:get(grabbed.Holder, Components.CharacterRef)
            if victimCharacterRef and holderCharacterRef then
                const holderRightArm = holderCharacterRef.Model:FindFirstChild("Right Arm")
                const motor = holderRightArm and holderRightArm:FindFirstChild("GrabHold")
                if motor then
                    motor:Destroy()
                end

                victimCharacterRef.Root.RootPriority = 0
            end
        end
    end)

    
end

return GrabAttachmentService