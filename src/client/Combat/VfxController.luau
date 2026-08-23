--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const TweenService = game:GetService("TweenService")

const Dash = require(ReplicatedStorage.Shared.Combat.Data.Dash)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const VfxManifest = require(ReplicatedStorage.Shared.Combat.Data.VfxManifest)
const Scheduler = require(ReplicatedStorage.Shared.Combat.Scheduler)
const StretchArm = require(ReplicatedStorage.Shared.Combat.Data.StretchArm)
const GatlingArm = require(ReplicatedStorage.Shared.Combat.Data.GatlingArm)

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
const DEFAULT_EMIT = 25
const STRETCH_ARM_NAME = "Right Arm"
const STRETCH_SHOULDER_OFFSET = Vector3.new(0, 0.9, 0)
const STRETCH_GUST_EMITS = 5
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
const GATLING_TRAIL_FRACTION = 0.25

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

function VfxController:_PlayGatling(character:Model, profile: GatlingArm.Profile, durationTicks: number)
    const root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if not root:IsA("BasePart") then return end

    const sourceArm = character:FindFirstChild(STRETCH_ARM_NAME)
    const armColor = if sourceArm and sourceArm:IsA("BasePart") then sourceArm.Color else Color3.new(1, 1, 1)

    const barrageTime = Scheduler.TicksToSeconds(durationTicks)
    const punchTime = Scheduler.TicksToSeconds(profile.PunchTicks)
    const spawnInterval = Scheduler.TicksToSeconds(profile.Interval / 3)

    type Punch = { Part: BasePart, P0: Vector3, P1: Vector3, P2: Vector3, Elapsed: number }
    const punches: { Punch } = {}

    local elapsed = 0
    local nextSpawn = 0
    local connection: RBXScriptConnection?

    const function Stop()
        if connection then
            connection:Disconnect()
        end

        for _, punch in punches do
            punch.Part:Destroy()
        end

        for _, armName in ARM_NAMES do
            const limb = character:FindFirstChild(armName)
            if limb and limb:IsA("BasePart") then
                limb.LocalTransparencyModifier = 0
            end
        end
    end

    const function Spawn()
        -- Each punch is launched off the root's facing at its own spawn moment, then
        -- flies that line to the end. Sampling the root live per frame would bend an
        -- in-flight arm sideways whenever the player swings their aim.
        const origin = root.CFrame
        const side = if math.random() < 0.5 then -1 else 1

        const startLocal = Vector3.new(
            side * profile.SpreadX * (0.5 + math.random() * 0.5),
            (math.random() - 0.5) * 2 * profile.SpreadY,
            0
        )

        const p0 = origin:PointToWorldSpace(startLocal)
        const p2 = origin:PointToWorldSpace(Vector3.new(startLocal.X * 0.2, startLocal.Y * 0.2, -profile.Reach))
        const p1 = (p0 + p2) / 2 + origin.RightVector * (side * profile.Curve)

        const burstPoint = p0 + origin.LookVector * profile.BurstOffset
        self:_EmitBurst(CFrame.lookAt(burstPoint, p0 + origin.LookVector), VfxManifest.PrefabMap.GatlingArm)

        const part = Instance.new("Part")
        part.Size = Vector3.new(profile.Thickness, profile.Thickness, 1)
        part.Color = armColor
        part.Material = Enum.Material.SmoothPlastic
        part.Anchored = true
        part.Massless = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.CastShadow = false
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
        part.Parent = workspace

        table.insert(punches, { Part = part, P0 = p0, P1 = p1, P2 = p2, Elapsed = 0 })
    end

    connection = RunService.RenderStepped:Connect(function(deltaTime: number)
        if not root.Parent then
            Stop()
            return
        end

        elapsed += deltaTime

        if elapsed < barrageTime then
            while elapsed >= nextSpawn do
                nextSpawn += spawnInterval
                Spawn()
            end
        end

        for _, armName in ARM_NAMES do
            const limb = character:FindFirstChild(armName)
            if limb and limb:IsA("BasePart") then
                limb.LocalTransparencyModifier = 1
            end
        end

        for index = #punches, 1, -1 do
            const punch = punches[index]
            punch.Elapsed += deltaTime

            const t = punch.Elapsed / punchTime
            if t >= 1 then
                punch.Part:Destroy()
                table.remove(punches, index)
                continue
            end

            const head = self:_Bezier(punch.P0, punch.P1, punch.P2, t)
            const tail = self:_Bezier(punch.P0, punch.P1, punch.P2, math.max(t - GATLING_TRAIL_FRACTION, 0))
            const span = head - tail
            if span.Magnitude < 0.001 then continue end

            punch.Part.Size = Vector3.new(profile.Thickness, profile.Thickness, span.Magnitude)
            punch.Part.CFrame = CFrame.lookAt(tail + span / 2, head)
        end

        if elapsed >= barrageTime and #punches == 0 then
            Stop()
        end
    end)
end

function VfxController:_PlayStretchArm(character: Model, profile: StretchArm.Profile, prefabName: string, aim: Vector3?)
    const root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if not root:IsA("BasePart") then return end

    const arm = character:FindFirstChild(STRETCH_ARM_NAME)
    if not arm then return end
    if not arm:IsA("BasePart") then return end

    const rubber = Instance.new("Part")
    rubber.Size = Vector3.new(profile.Thickness, profile.Thickness, 1)
    rubber.Color = arm.Color
    rubber.Material = Enum.Material.SmoothPlastic
    rubber.Anchored = true
    rubber.Massless = true
    rubber.CanCollide = false
    rubber.CanQuery = false
    rubber.CanTouch = false
    rubber.CastShadow = false
    rubber.TopSurface = Enum.SurfaceType.Smooth
    rubber.BottomSurface = Enum.SurfaceType.Smooth
    rubber.LeftSurface = Enum.SurfaceType.Smooth
    rubber.RightSurface = Enum.SurfaceType.Smooth
    rubber.FrontSurface = Enum.SurfaceType.Smooth
    rubber.BackSurface = Enum.SurfaceType.Smooth
    rubber.Parent = workspace

    const gust = Instance.new("Part")
    gust.Size = Vector3.one
    gust.Transparency = 1
    gust.Anchored = true
    gust.Massless = true
    gust.CanCollide = false
    gust.CanQuery = false
    gust.CanTouch = false
    gust.CastShadow = false
    gust.Parent = workspace

    const gustEmitters: { ParticleEmitter } = {}
    const gustFolder = if VfxAssets then VfxAssets:FindFirstChild(prefabName) else nil

    if gustFolder then
        const template = gustFolder:FindFirstChildWhichIsA("Attachment")
        const gustAttachment = if template then template:Clone() else Instance.new("Attachment")
        gustAttachment.Parent = gust

        if not template then
            for _, child in gustFolder:GetChildren() do
                if not child:IsA("ParticleEmitter") then continue end
                child:Clone().Parent = gustAttachment
            end
        end

        for _, descendant in gustAttachment:GetDescendants() do
            if not descendant:IsA("ParticleEmitter") then continue end
            descendant.Enabled = false
            table.insert(gustEmitters, descendant)
        end
    end

    const gustLifetime = if gustFolder then self:_GetMaxLifetime(gustFolder) else 0
    local gustsFired = 0

    const function EmitGust()
        for _, emitter in gustEmitters do
            const emitCount = emitter:GetAttribute("EmitCount")
            if typeof(emitCount) == "number" then
                emitter:Emit(emitCount)
            else
                emitter:Emit(DEFAULT_EMIT)
            end
        end
    end

    for _ = 1, STRETCH_GUST_EMITS do
        EmitGust()
    end

    -- The animation keeps swinging the arm part after the launch, so the shoulder is
    -- captured once, in root space. Reading it live would bend the limb off the line the
    -- hitbox travels.
    const shoulderOffset = root.CFrame:PointToObjectSpace(arm.CFrame:PointToWorldSpace(STRETCH_SHOULDER_OFFSET))

    -- The server sends the facing it froze the hitbox to. Reading the root here instead
    -- aims the limb wherever the attacker has turned since, which is what made the arm
    -- and the hitbox disagree.
    const direction = if aim and aim.Magnitude > 0.001 then aim.Unit else root.CFrame.LookVector

    const extendTime = Scheduler.TicksToSeconds(profile.ExtendTicks)
    const returnTime = Scheduler.TicksToSeconds(profile.ReturnTicks)

    local elapsed = 0
    local connection: RBXScriptConnection?

    const function Stop()
        if connection then
            connection:Disconnect()
        end
        arm.LocalTransparencyModifier = 0
        rubber:Destroy()

        for _, emitter in gustEmitters do
            emitter.Enabled = false
        end

        task.delay(gustLifetime, function()
            gust:Destroy()
        end)
    end

    connection = RunService.RenderStepped:Connect(function(deltaTime: number)
        if not root.Parent or not arm.Parent then
            Stop()
            return
        end

        elapsed += deltaTime

        local alpha
        if elapsed <= extendTime then
            alpha = TweenService:GetValue(elapsed / extendTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        else
            const returning = (elapsed - extendTime) / returnTime
            if returning >= 1 then
                Stop()
                return
            end
            alpha = 1 - TweenService:GetValue(returning, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        end

        arm.LocalTransparencyModifier = 1

        const shoulder = root.CFrame:PointToWorldSpace(shoulderOffset)
        const distance = profile.StartRange + (profile.MaxRange - profile.StartRange) * alpha

        -- The limb runs straight out of the shoulder. Aiming it at the hitbox centre
        -- instead pulls the near end across the chest; the hitbox is wide enough that
        -- a shoulder-aligned arm still sits inside it.
        const tip = shoulder + direction * distance
        const span = tip - shoulder
        if span.Magnitude < 0.001 then return end

        rubber.Size = Vector3.new(profile.Thickness, profile.Thickness, span.Magnitude)
        rubber.CFrame = CFrame.lookAt(shoulder + span / 2, tip)
        gust.CFrame = CFrame.lookAt(tip, tip + direction)

        const due = math.floor(math.min(elapsed / extendTime, 1) * STRETCH_GUST_EMITS)
        while gustsFired < due do
            gustsFired += 1
            EmitGust()
        end
    end)
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

    GroundSlam = function(character: Model, data: Packets.VfxPayload)
        VfxController:_PlayGroundSlam(character, data.Position)
    end,

    Block = function(character: Model, _data: Packets.VfxPayload)
        VfxController:_EmitAtRoot(character, VfxManifest.PrefabMap.Block)
    end,

    BlockBreak = function(character: Model, _data: Packets.VfxPayload)
        VfxController:_EmitAtRoot(character, VfxManifest.PrefabMap.BlockBreak)
    end,

    PistolArm = function(character: Model, data: Packets.VfxPayload)
        VfxController:_PlayStretchArm(character, StretchArm.Pistol, VfxManifest.PrefabMap.PistolArm, data.Direction)
    end,

    GatlingArm = function(character: Model, data: Packets.VfxPayload)
        VfxController:_PlayGatling(character, GatlingArm, data.Duration)
    end
}

return VfxController