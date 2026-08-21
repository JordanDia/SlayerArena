--!strict
const PhysicsService = game:GetService("PhysicsService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Jecs = require(ReplicatedStorage.Packages.Jecs)
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Ragdoll = require(ReplicatedStorage.Shared.Combat.Data.Ragdoll)
const World = require(ReplicatedStorage.Shared.Combat.World)

const RagdollService = {}

function RagdollService:Init()
    if not PhysicsService:IsCollisionGroupRegistered("Thrown") then
        PhysicsService:RegisterCollisionGroup("Thrown")
    else
        warn("GrabAttachmentService cannot make collision group 'Thrown', it's already registered")
    end

    PhysicsService:CollisionGroupSetCollidable("Thrown", "Combatant", false)
    PhysicsService:CollisionGroupSetCollidable("Thrown", "Thrown", false)

    if not PhysicsService:IsCollisionGroupRegistered("Ghost") then
        PhysicsService:RegisterCollisionGroup("Ghost")
    end

    PhysicsService:CollisionGroupSetCollidable("Ghost", "Default", false)
    PhysicsService:CollisionGroupSetCollidable("Ghost", "Combatant", false)
    PhysicsService:CollisionGroupSetCollidable("Ghost", "Thrown", false)
    PhysicsService:CollisionGroupSetCollidable("Ghost", "Ghost", false)

    World:added(Components.Ragdolled, function(entity: World.Entity, _componentId: Jecs.Id<Components.Ragdolled>, _value: Components.Ragdolled, _oldarchetype: Jecs.Archetype)
        const characterRef = World:get(entity, Components.CharacterRef)
        if not characterRef then return end

        const torso = characterRef.Model:FindFirstChild("Torso") :: BasePart?
        if not torso then return end

        for _, jointName in Ragdoll.JointNames do
            const motor = torso:FindFirstChild(jointName) :: Motor6D?
            if not motor then continue end
            if not motor.Part0 or not motor.Part1 then continue end

            const attachment0 = Instance.new("Attachment")
            attachment0.Name = "RagdollAttachment"
            attachment0.CFrame = motor.C0
            attachment0.Parent = motor.Part0
            
            const attachment1 = Instance.new("Attachment")
            attachment1.Name = "RagdollAttachment"
            attachment1.CFrame = motor.C1
            attachment1.Parent = motor.Part1

            const socket = Instance.new("BallSocketConstraint")
            socket.Name = "RagdollSocket"
            socket.Attachment0 = attachment0
            socket.Attachment1 = attachment1
            socket.LimitsEnabled = true
            socket.TwistLimitsEnabled = true
            socket.TwistLowerAngle = Ragdoll.TwistLowerAngle
            socket.TwistUpperAngle = Ragdoll.TwistUpperAngle
            socket.UpperAngle = Ragdoll.UpperAngle
            socket.Parent = motor.Part0
            
            motor.Enabled = false
        end
    end)

    World:removed(Components.Ragdolled, function(entity: World.Entity, _componentId: Jecs.Id<Components.Ragdolled>, isDeleting: boolean?)
        if isDeleting then return end

        const characterRef = World:get(entity, Components.CharacterRef)
        if not characterRef then return end

        for _, descendant in characterRef.Model:GetDescendants() do
            if descendant.Name == "RagdollSocket" or descendant.Name == "RagdollAttachment" then
                descendant:Destroy()
            end
        end

        const torso = characterRef.Model:FindFirstChild("Torso") :: BasePart?
        if not torso then return end

        for _, jointName in Ragdoll.JointNames do
            const motor = torso:FindFirstChild(jointName) :: Motor6D?
            if not motor then continue end

            motor.Enabled = true
        end
    end)

    World:added(Components.Thrown, function(entity: World.Entity, _componentId: Jecs.Id<Components.Thrown>, _value: Components.Thrown, _oldarchetype: Jecs.Archetype)
        const victimCharacterRef = World:get(entity, Components.CharacterRef)
        if not victimCharacterRef then return end

        for _, part in victimCharacterRef.Model:GetDescendants() do
            if not part:IsA("BasePart") then continue end
            part.CollisionGroup = "Thrown"
        end

        victimCharacterRef.Humanoid.PlatformStand = true
    end)

    World:removed(Components.Thrown, function(entity: World.Entity, _componentId: Jecs.Id<Components.Thrown>, isDeleting: boolean?)
        if isDeleting then return end

        const victimCharacterRef = World:get(entity, Components.CharacterRef)
        if not victimCharacterRef then return end

        for _, part in victimCharacterRef.Model:GetDescendants() do
            if not part:IsA("BasePart") then continue end
            part.CollisionGroup = "Combatant"
        end

        const victimPlayerRef = World:get(entity, Components.PlayerRef)
        if victimPlayerRef then
            victimCharacterRef.Root:SetNetworkOwnershipAuto()
        else
            victimCharacterRef.Root:SetNetworkOwner(nil)
        end

        victimCharacterRef.Humanoid.PlatformStand = false
        
    end)
end

return RagdollService