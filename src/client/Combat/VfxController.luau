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
const KNOCKBACK_DURATION_SCALE = 4
const ARM_NAMES = { "Right Arm", "Left Arm" }
const GEPPO_DROP = 0
const GEPPO_DEFAULT_EMIT = 15
const DEFAULT_EMIT = 25
-- The prefab is authored lying on its side, so this rights it after it is aimed.
const GEPPO_PREFAB_ROTATION = CFrame.Angles(0, math.rad(90), 0)
const RUBBLE_COUNT = 9
const RUBBLE_RADIUS_MIN = 2.5
const RUBBLE_RADIUS_MAX = 5
const RUBBLE_SIZE_MIN = 0.8
const RUBBLE_SIZE_MAX = 2.4
const RUBBLE_ANGLE_JITTER = 0.4
const RUBBLE_TILT_MIN = 15
const RUBBLE_TILT_MAX = 50
const RUBBLE_RISE_FRACTION = 0.35
const RUBBLE_RISE_TIME = 0.12
const RUBBLE_HOLD_TIME = 0.45
const RUBBLE_SINK_TIME = 0.5
const RUBBLE_CAST_UP = 2
const RUBBLE_CAST_DOWN = 8
const RUBBLE_FALLBACK_COLOR = Color3.fromRGB(120, 120, 120)

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

function VfxController:_EmitAtRoot(character: Model, prefabName: string)
    if not VfxAssets then return end

    const root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    const rootAttachment = root:FindFirstChild("RootAttachment")
    if not rootAttachment then return end

    const vfxFolder = VfxAssets:FindFirstChild(prefabName)
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
            vfx:Emit(DEFAULT_EMIT)
        end
    end

    const maxLifetime = self:_GetMaxLifetime(vfxFolder)

    task.delay(maxLifetime, function()
        for _, vfx in particles do
            vfx:Destroy()
        end
    end)
end

function VfxController:_PlayHit(character: Model)
    self:_EmitAtRoot(character, VfxManifest.PrefabMap.Hit)
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
    self:_EmitAtRoot(character, VfxManifest.PrefabMap.PerfectBlock)
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

function VfxController:_ResolveGroundLook(position: Vector3, ignore: Model?): (Color3, Enum.Material)
    const params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { ghostFolder, ignore :: any }
    params.IgnoreWater = true

    const result = workspace:Raycast(position + Vector3.yAxis * RUBBLE_CAST_UP, -Vector3.yAxis * RUBBLE_CAST_DOWN, params)
    if not result then return RUBBLE_FALLBACK_COLOR, Enum.Material.Slate end

    if result.Instance:IsA("Terrain") then
        const success, color = pcall(function()
            return workspace.Terrain:GetMaterialColor(result.Material)
        end)
        return (if success then color else RUBBLE_FALLBACK_COLOR), result.Material
    end

    return result.Instance.Color, result.Material
end

function VfxController:_PlayGroundSlam(character: Model, position: Vector3?)
    if not position then return end

    const color, material = self:_ResolveGroundLook(position, character)

    for index = 1, RUBBLE_COUNT do
        const angle = (index - 1) / RUBBLE_COUNT * math.pi * 2 + math.random() * RUBBLE_ANGLE_JITTER
        const radius = RUBBLE_RADIUS_MIN + math.random() * (RUBBLE_RADIUS_MAX - RUBBLE_RADIUS_MIN)
        const outward = Vector3.new(math.cos(angle), 0, math.sin(angle))

        const size = Vector3.new(
            RUBBLE_SIZE_MIN + math.random() * (RUBBLE_SIZE_MAX - RUBBLE_SIZE_MIN),
            RUBBLE_SIZE_MIN + math.random() * (RUBBLE_SIZE_MAX - RUBBLE_SIZE_MIN),
            RUBBLE_SIZE_MIN + math.random() * (RUBBLE_SIZE_MAX - RUBBLE_SIZE_MIN)
        )

        const rock = Instance.new("Part")
        rock.Size = size
        rock.Color = color
        rock.Material = material
        rock.Anchored = true
        rock.CanCollide = false
        rock.CanQuery = false
        rock.CanTouch = false
        rock.CastShadow = false
        rock.TopSurface = Enum.SurfaceType.Smooth
        rock.BottomSurface = Enum.SurfaceType.Smooth

        const spot = position + outward * radius
        const tilt = math.rad(RUBBLE_TILT_MIN + math.random() * (RUBBLE_TILT_MAX - RUBBLE_TILT_MIN))
        const rotation = CFrame.lookAt(Vector3.zero, outward)
            * CFrame.Angles(tilt, 0, 0)
            * CFrame.Angles(0, 0, math.random() * math.pi * 2)

        const buried = CFrame.new(spot - Vector3.yAxis * size.Y) * rotation
        const risen = CFrame.new(spot + Vector3.yAxis * size.Y * RUBBLE_RISE_FRACTION) * rotation

        rock.CFrame = buried
        rock.Parent = workspace

        const riseTween = TweenService:Create(
            rock,
            TweenInfo.new(RUBBLE_RISE_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { CFrame = risen }
        )

        const sinkTween = TweenService:Create(
            rock,
            TweenInfo.new(RUBBLE_SINK_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { CFrame = buried, Transparency = 1 }
        )

        riseTween:Play()

        task.delay(RUBBLE_RISE_TIME + RUBBLE_HOLD_TIME, function()
            if not rock.Parent then return end
            sinkTween:Play()
        end)

        task.delay(RUBBLE_RISE_TIME + RUBBLE_HOLD_TIME + RUBBLE_SINK_TIME, function()
            rock:Destroy()
        end)
    end
end

function VfxController:_EmitBurst(cframe: CFrame, prefabName: string)
    const folder = if VfxAssets then VfxAssets:FindFirstChild(prefabName) else nil
    if not folder then return end

    const part = Instance.new("Part")
    part.Size = Vector3.one
    part.Transparency = 1
    part.Anchored = true
    part.Massless = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.CFrame = cframe
    part.Parent = workspace

    const template = folder:FindFirstChildWhichIsA("Attachment")
    const attachment = if template then template:Clone() else Instance.new("Attachment")
    attachment.Parent = part

    if not template then
        for _, child in folder:GetChildren() do
            if not child:IsA("ParticleEmitter") then continue end
            child:Clone().Parent = attachment
        end
    end

    for _, descendant in attachment:GetDescendants() do
        if not descendant:IsA("ParticleEmitter") then continue end
        descendant.Enabled = false

        const emitCount = descendant:GetAttribute("EmitCount")
        descendant:Emit(if typeof(emitCount) == "number" then emitCount else DEFAULT_EMIT)
    end

    task.delay(self:_GetMaxLifetime(folder), function()
        part:Destroy()
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

function VfxController:_Bezier(p0: Vector3, p1: Vector3, p2: Vector3, t: number): Vector3
    const u = 1 - t
    return u * u * p0 + 2 * u * t * p1 + t * t * p2
end

handlers = {
    Hit = function(character: Model, _data: Packets.VfxPayload)
        VfxController:_PlayHit(character)
    end,

    Knockback = function(character: Model, data: Packets.VfxPayload)
        VfxController:_PlayKnockback(character, data.Duration * KNOCKBACK_DURATION_SCALE)
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

    GroundSlam = function(character: Model, data: Packets.VfxPayload)
        VfxController:_PlayGroundSlam(character, data.Position)
    end,

    Block = function(character: Model, _data: Packets.VfxPayload)
        VfxController:_EmitAtRoot(character, VfxManifest.PrefabMap.Block)
    end,

    BlockBreak = function(character: Model, _data: Packets.VfxPayload)
        VfxController:_EmitAtRoot(character, VfxManifest.PrefabMap.BlockBreak)
    end
}

return VfxController