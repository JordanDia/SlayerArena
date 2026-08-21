--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const TweenService = game:GetService("TweenService")

const Dash = require(ReplicatedStorage.Shared.Combat.Data.Dash)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const VfxManifest = require(ReplicatedStorage.Shared.Combat.Data.VfxManifest)
const Scheduler = require(ReplicatedStorage.Shared.Combat.Scheduler)

local VfxAssets: Folder
local ghostFolder: Folder

-- stores functions to stop knockback VFX for characters
const activeKnockbacks: { [Model]: () -> () } = {}

const FADE_IN_TRANSPARENCY = 0
const FADE_OUT_TRANSPARENCY = 1
const FADE_TIME = 0.1
const HIT_HIGHLIGHT_COLOR = Color3.fromRGB(255, 0, 0)
const DODGE_HIGHLIGHT_COLOR = Color3.fromRGB(255, 255, 255)
const KNOCKBACK_DURATION_SCALE = 4
const ARM_NAMES = { "Right Arm", "Left Arm" }
const GEPPO_DROP = 0
const GEPPO_DEFAULT_EMIT = 15
-- The prefab is authored lying on its side, so this rights it after it is aimed.
const GEPPO_PREFAB_ROTATION = CFrame.Angles(0, math.rad(90), 0)

local handlers: { [VfxManifest.VfxKind]: (character: Model, data: Packets.VfxPayload) -> () }

const VfxController = {}

function VfxController:Init()
    VfxAssets = ReplicatedStorage.Assets.VFX

    ghostFolder = Instance.new("Folder")
    ghostFolder.Name = "DashGhosts"
    ghostFolder.Parent = workspace
end

function VfxController:Start()

    Packets.Vfx.listen(function(data: Packets.VfxPayload)
        if not data.Character then return end
        if not data.Character:IsA("Model") then return end
        if not data.Kind then return end

        if not VfxAssets then
            warn("Cannot find VFX folder")
            return
        end

        const vfxKind: VfxManifest.VfxKind = VfxManifest.ByteMap[data.Kind]
        if not vfxKind then return end

        const handler = handlers[vfxKind]
        if not handler then
            warn(`No VFX handler for kind: { vfxKind }`)
            return
        end

        handler(data.Character, data)
    end)
end

function VfxController:_PlayHit(character: Model, vfxAssets: Instance)
    const root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    const rootAttachment = root:FindFirstChild("RootAttachment")
    if not rootAttachment then return end

    const vfxFolder = vfxAssets:FindFirstChild(VfxManifest.PrefabMap.Hit)
    if not vfxFolder then return end

    const particles: { ParticleEmitter } = {}
    for _, child in vfxFolder:GetChildren() do
        if not child:IsA("ParticleEmitter") then continue end
        const vfx = child:Clone()
        table.insert(particles, vfx)

        vfx.Parent = rootAttachment
    end

    for _, vfx in particles do
        const emitCount = vfx:GetAttribute("EmitCount")
        if typeof(emitCount) == "number" then
            vfx:Emit(emitCount)
        else
            vfx:Emit(25)
        end
    end

    const maxLifetime = self:_GetMaxLifetime(vfxFolder)

    task.delay(maxLifetime, function()
        for _, vfx in particles do
            vfx:Destroy()
        end
    end)

    self:_Highlight(character, HIT_HIGHLIGHT_COLOR)
end

function VfxController:_PlayKnockback(character: Model, duration: number)
    
    const root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if not root:IsA("BasePart") then return end

    if activeKnockbacks[character] then
        activeKnockbacks[character]()
    end

    const humanoid =  character:FindFirstChild("Humanoid") :: Humanoid?
    if not humanoid then return end
    
    const prefab = VfxAssets:FindFirstChild(VfxManifest.PrefabMap.Knockback)
    if not prefab then return end
    if not prefab:IsA("BasePart") then return end

    const vfxPart = prefab:Clone()
    vfxPart.CFrame = root.CFrame
    vfxPart.Anchored = true
    vfxPart.CanCollide = false
    vfxPart.CanQuery = false
    vfxPart.CanTouch = false
    vfxPart.Parent = character
    
    local stopped = false
    local renderConnection: RBXScriptConnection?
    local floorConnection: RBXScriptConnection?
    local hasLeftGround = false
    local lastGoodCFrame = root.CFrame -- for near zero velocity

    const maxLifetime = self:_GetMaxLifetime(vfxPart)

    local function Stop()
        if stopped then return end
        stopped = true

        if renderConnection then
            renderConnection:Disconnect()
        end

        if floorConnection then
            floorConnection:Disconnect()
        end

        for _, particle in vfxPart:GetChildren() do
            if not particle:IsA("ParticleEmitter") then continue end
            particle.Enabled = false
        end

        -- we stopped the vfx, so deregister this function so we cannot use it again
        if activeKnockbacks[character] == Stop then
            activeKnockbacks[character] = nil
        end

        task.delay(maxLifetime, function()
            vfxPart:Destroy()
        end)
    end

    activeKnockbacks[character] = Stop

    renderConnection = RunService.RenderStepped:Connect(function(_deltaTime: number)
        if not root.Parent then return end
        if not vfxPart.Parent then return end

        local cframe = CFrame.lookAt(root.Position, root.Position + root.AssemblyLinearVelocity)
            * CFrame.Angles(math.rad(-90), 0, 0)
            
        if root.AssemblyLinearVelocity.Magnitude < 0.1 then
            cframe = lastGoodCFrame
        end
        vfxPart.CFrame = cframe
        lastGoodCFrame = cframe
    end)

    floorConnection = humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
        if humanoid.FloorMaterial == Enum.Material.Air then
            hasLeftGround = true
        else
            if hasLeftGround then
                Stop()
            end
        end
    end)

    task.delay(Scheduler.TicksToSeconds(duration), Stop)

    self:_Highlight(character, HIT_HIGHLIGHT_COLOR)
end

function VfxController:_Highlight(character: Model, color: Color3)
    const highlight = Instance.new("Highlight")
    
    highlight.FillTransparency = 1
    highlight.FillColor = color
    highlight.OutlineTransparency = 1
    highlight.Parent = character

    const tweenInfo = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear)
    const fadeIn = TweenService:Create(highlight, tweenInfo, { FillTransparency = FADE_IN_TRANSPARENCY })
    const fadeOut = TweenService:Create(highlight, tweenInfo, { FillTransparency = FADE_OUT_TRANSPARENCY })

    fadeIn.Completed:Connect(function()
        fadeOut:Play()
    end)

    fadeOut.Completed:Connect(function()
        highlight:Destroy()
    end)
    
    fadeIn:Play()
end

function VfxController:_SpawnGhost(character: Model)
    if not ghostFolder then return end

    const ghost = Instance.new("Model")
    ghost.Name = `{ character.Name }_Ghost`

    const parts: { BasePart } = {}

    for _, descendant in character:GetDescendants() do
        if not descendant:IsA("BasePart") then continue end
        if descendant.Transparency >= 1 then continue end
        if descendant:FindFirstAncestorOfClass("Accessory") then continue end

        const part = descendant:Clone()
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.CastShadow = false
        part.Massless = true
        part.CollisionGroup = "Ghost"
        part.Transparency = Dash.GhostTransparency
        part.Color = Dash.GhostColor
        part.Material = Enum.Material.Neon
        part.CFrame = descendant.CFrame

        for _, child in part:GetDescendants() do
            if child:IsA("JointInstance") or child:IsA("WeldConstraint") or child:IsA("Attachment") or child:IsA("ParticleEmitter") or child:IsA("Decal") then
                child:Destroy()
            end
        end

        part.Parent = ghost
        table.insert(parts, part)
    end

    if #parts == 0 then
        ghost:Destroy()
        return
    end

    ghost.Parent = ghostFolder

    const tweenInfo = TweenInfo.new(Dash.GhostLifetime, Enum.EasingStyle.Linear)
    for _, part in parts do
        TweenService:Create(part, tweenInfo, { Transparency = 1 }):Play()
    end

    task.delay(Dash.GhostLifetime, function()
        ghost:Destroy()
    end)
end

function VfxController:_PlayPerfectBlock(character: Model)
    if not VfxAssets then return end

    const root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    const rootAttachment = root:FindFirstChild("RootAttachment")
    if not rootAttachment then return end

    const vfxFolder = VfxAssets:FindFirstChild(VfxManifest.PrefabMap.PerfectBlock)
    if not vfxFolder then return end

    const particles: { ParticleEmitter } = {}
    for _, child in vfxFolder:GetChildren() do
        if not child:IsA("ParticleEmitter") then continue end

        const vfx = child:Clone()
        vfx.Parent = rootAttachment
        table.insert(particles, vfx)
    end

    for _, vfx in particles do
        const emitCount = vfx:GetAttribute("EmitCount")
        if typeof(emitCount) == "number" then
            vfx:Emit(emitCount)
        else
            vfx:Emit(25)
        end
    end

    const maxLifetime = self:_GetMaxLifetime(vfxFolder)

    task.delay(maxLifetime, function()
        for _, vfx in particles do
            vfx:Destroy()
        end
    end)
end

function VfxController:_PlayDash(character: Model, duration: number)

    const root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if not root:IsA("BasePart") then return end

    if not VfxAssets then return end

    const prefab = VfxAssets:FindFirstChild(VfxManifest.PrefabMap.Dash)
    if not prefab then return end
    if not prefab:IsA("BasePart") then return end

    const vfxPart = prefab:Clone()
    vfxPart.CFrame = root.CFrame
    vfxPart.Anchored = true
    vfxPart.CanCollide = false
    vfxPart.CanQuery = false
    vfxPart.CanTouch = false
    vfxPart.Parent = character

    local stopped = false
    local renderConnection: RBXScriptConnection? = nil
    local lastGoodCFrame = root.CFrame
    local ghostsSpawned = 0

    const maxLifetime = self:_GetMaxLifetime(vfxPart)

    const function Stop()
        if stopped then return end
        stopped = true

        if renderConnection then
            renderConnection:Disconnect()
        end

        for _, particle in vfxPart:GetChildren() do
            if not particle:IsA("ParticleEmitter") then continue end
            particle.Enabled = false
        end

        task.delay(maxLifetime, function()
            vfxPart:Destroy()
        end)
    end


    const ghostInterval = Scheduler.TicksToSeconds(duration) / Dash.GhostCount

    local ghostTimer = ghostInterval
    renderConnection = RunService.RenderStepped:Connect(function(deltaTime: number)
        if not root.Parent then return end
        if not vfxPart.Parent then return end

        local cframe = CFrame.lookAt(root.Position, root.Position + root.AssemblyLinearVelocity)
            * CFrame.Angles(math.rad(-90), 0, 0)

        if root.AssemblyLinearVelocity.Magnitude < 0.1 then
            cframe = lastGoodCFrame
        end

        vfxPart.CFrame = cframe
        lastGoodCFrame = cframe

        ghostTimer += deltaTime

        if ghostsSpawned < Dash.GhostCount and ghostTimer >= ghostInterval then
            ghostsSpawned += 1
            VfxController:_SpawnGhost(character)
            ghostTimer -= ghostInterval
        end
    end)

    task.delay(Scheduler.TicksToSeconds(duration), Stop)
end

function VfxController:_PlaySwingTrail(character: Model, duration: number)
    if not VfxAssets then return end

    const prefab = VfxAssets:FindFirstChild(VfxManifest.PrefabMap.SwingTrail)
    if not prefab then return end

    const cloned: { Instance } = {}
    const trails: { Trail } = {}

    for _, armName in ARM_NAMES do
        const arm = character:FindFirstChild(armName)
        if not arm then continue end
        if not arm:IsA("BasePart") then continue end

        const prefabClone = prefab:Clone()
        for _, child in prefabClone:GetChildren() do
            child.Parent = arm
            table.insert(cloned, child)

            if not child:IsA("Trail") then continue end
            child.Enabled = true
            table.insert(trails, child)
        end

        prefabClone:Destroy()
    end

    task.delay(Scheduler.TicksToSeconds(duration), function()
        local maxLifetime = 0

        for _, trail in trails do
            trail.Enabled = false
            maxLifetime = math.max(trail.Lifetime, maxLifetime)
        end

        task.delay(maxLifetime, function()
            for _, instance in cloned do
                instance:Destroy()
            end
        end)
    end)
end

function VfxController:_PlayGeppo(character: Model, direction: Vector3?)
    if not VfxAssets then return end

    const root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if not root:IsA("BasePart") then return end

    const prefab = VfxAssets:FindFirstChild(VfxManifest.PrefabMap.Geppo)
    if not prefab then return end

    const template = if prefab:IsA("BasePart") then prefab else prefab:FindFirstChildWhichIsA("BasePart")
    if not template then return end

    const position = root.Position - Vector3.yAxis * GEPPO_DROP

    const aim = if direction and direction.Magnitude > 0.001 then direction.Unit else Vector3.yAxis

    -- CFrame.lookAt degenerates when the aim is parallel to its default up vector, which
    -- a neutral geppo is exactly - it goes straight up. Hand it a different up in that case.
    const up = if math.abs(aim.Y) > 0.99 then Vector3.zAxis else Vector3.yAxis

    const vfxPart = template:Clone()
    vfxPart.CFrame = CFrame.lookAt(position, position + aim, up) * GEPPO_PREFAB_ROTATION
    vfxPart.Anchored = true
    vfxPart.CanCollide = false
    vfxPart.CanQuery = false
    vfxPart.CanTouch = false
    vfxPart.Parent = workspace

    for _, vfx in vfxPart:GetDescendants() do
        if not vfx:IsA("ParticleEmitter") then continue end

        const emitCount = vfx:GetAttribute("EmitCount")
        if typeof(emitCount) == "number" then
            vfx:Emit(emitCount)
        else
            vfx:Emit(GEPPO_DEFAULT_EMIT)
        end
    end

    task.delay(self:_GetMaxLifetime(vfxPart), function()
        vfxPart:Destroy()
    end)
end

function VfxController:_GetMaxLifetime(container: Instance): number
    local maxLifetime = 0
    for _, vfx in container:GetDescendants() do
        if not vfx:IsA("ParticleEmitter") then continue end
        maxLifetime = math.max(vfx.Lifetime.Max, maxLifetime)
    end
    if maxLifetime == 0 then
        maxLifetime = 5
    end

    return maxLifetime
end

handlers = {
    Hit = function(character: Model, _data: Packets.VfxPayload)
        VfxController:_PlayHit(character, VfxAssets)
    end,

    Knockback = function(character: Model, data: Packets.VfxPayload)
        VfxController:_PlayKnockback(character, data.Duration * KNOCKBACK_DURATION_SCALE)
    end,

    Dodge = function(character: Model, _data: Packets.VfxPayload)
        VfxController:_Highlight(character, DODGE_HIGHLIGHT_COLOR)
    end,

    SwingTrail = function(character: Model, data: Packets.VfxPayload)
        VfxController:_PlaySwingTrail(character, data.Duration)
    end,

    Dash = function(character: Model, data: Packets.VfxPayload)
        VfxController:_PlayDash(character, data.Duration)
    end,

    PerfectBlock = function(character: Model, _data: Packets.VfxPayload)
        VfxController:_PlayPerfectBlock(character)
    end,

    Geppo = function(character: Model, data: Packets.VfxPayload)
        VfxController:_PlayGeppo(character, data.Direction)
    end,
}

return VfxController