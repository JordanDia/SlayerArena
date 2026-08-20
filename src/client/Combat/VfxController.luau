--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const TweenService = game:GetService("TweenService")

const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const VfxManifest = require(ReplicatedStorage.Shared.Combat.Data.VfxManifest)
const Scheduler = require(ReplicatedStorage.Shared.Combat.Scheduler)

local VfxAssets: Folder

-- stores functions to stop knockback VFX for characters
const activeKnockbacks: { [Model]: () -> () } = {}

const FADE_IN_TRANSPARENCY = 0
const FADE_OUT_TRANSPARENCY = 1
const FADE_TIME = 0.1
const HIT_HIGHLIGHT_COLOR = Color3.fromRGB(255, 0, 0)
const DODGE_HIGHLIGHT_COLOR = Color3.fromRGB(255, 255, 255)

const VfxController = {}

function VfxController:Init()
    VfxAssets = ReplicatedStorage.Assets.VFX
end

function VfxController:Start()

    Packets.Vfx.listen(function(data: { Character: Instance, Kind: number, Duration: number})
        if not data.Character then return end
        if not data.Character:IsA("Model") then return end
        if not data.Kind then return end

        if not VfxAssets then
            warn("Cannot find VFX folder")
            return
        end

        const vfxKind: VfxManifest.VfxKind = VfxManifest.ByteMap[data.Kind]
        if not vfxKind then return end
        if vfxKind == "Hit" then
            self:_PlayHit(data.Character, VfxAssets)
        elseif vfxKind == "Knockback" then
            self:_PlayKnockback(data.Character, VfxAssets, data.Duration * 4)
        elseif vfxKind == "Dodge" then
            self:_Highlight(data.Character, DODGE_HIGHLIGHT_COLOR)
        end
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

function VfxController:_PlayKnockback(character: Model, vfxAssets: Instance, duration: number)
    
    const root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if not root:IsA("BasePart") then return end

    if activeKnockbacks[character] then
        activeKnockbacks[character]()
    end

    const humanoid =  character:FindFirstChild("Humanoid") :: Humanoid?
    if not humanoid then return end
    
    const prefab = vfxAssets:FindFirstChild(VfxManifest.PrefabMap.Knockback)
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

return VfxController