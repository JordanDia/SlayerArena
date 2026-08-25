--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")
const ServerStorage = game:GetService("ServerStorage")

const Components = require(ReplicatedStorage.Shared.Combat.Components)
const World = require(ReplicatedStorage.Shared.Combat.World)
const Dummies = require(ServerScriptService.Server.Combat.Data.Dummies)
const CombatantFactory = require(script.Parent.CombatantFactory)

const DummyService = {}

local dummyContainer: Folder
local dummyRigs: Folder
local spawns: Folder
const activeBySpawn: { [BasePart]: Model } = {}
const RESPAWN_DELAY = 2
const INDICATOR_HEIGHT = 6

function DummyService:Init()
    dummyContainer = Instance.new("Folder")
    dummyContainer.Name = "DummyContainer"
    dummyContainer.Parent = workspace
end

function DummyService:Start()
    dummyRigs = ServerStorage:WaitForChild("Dummies") :: Folder
    spawns = workspace:WaitForChild("DummySpawns") :: Folder

    for _, spawnPart in spawns:GetChildren() do
        self:_SpawnDummy(spawnPart)
    end
end

function DummyService:_SpawnDummy(spawnPart: BasePart)
    const kind = spawnPart.Name

    const dummyConfig = Dummies[kind]
    if not dummyConfig then
        warn(`Dummy type ({ kind }) not found in config!`)
        return
    end

    const dummyPrefab = dummyRigs:FindFirstChild("Dummy") :: Model?
    if not dummyPrefab or not dummyPrefab:IsA("Model") then
        warn(`Dummy type ({ kind }) not found in rig folder!`)
        return
    end

    const dummy = dummyPrefab:Clone()
    dummy.Name = kind
    dummy:PivotTo(spawnPart.CFrame)
    dummy.Parent = dummyContainer
    
    const root = dummy:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not root then
        warn(`Dummy type ({ kind }) rig has no HumanoidRootPart!`)
        dummy:Destroy()
        return
    end
    root:SetNetworkOwner(nil)

    const humanoid = dummy:FindFirstChild("Humanoid") :: Humanoid?
    if not humanoid then
        warn(`Dummy type ({ kind }) rig has no humanoid!`)
        dummy:Destroy()
        return
    end
    
    const entity = CombatantFactory.Create(dummy, dummyConfig.Stats)
    if not entity then
        warn("Failed to create dummy entity")
        dummy:Destroy()
        return
    end

    const indicatorPart = self:_CreateIndicator(dummy, root)
    
    const dummyComponent: Components.Dummy = {
        Kind = kind,
        Spawn = spawnPart,
        Indicator = indicatorPart
    }
    World:set(entity, Components.Dummy, dummyComponent)

    if dummyConfig.Behavior then
        const dummyBehavior: Components.DummyBehavior = {
            Policy = dummyConfig.Behavior.Policy,
            Interval = dummyConfig.Behavior.Interval,
            ArmedUntil = 0,
            NextActionAt = 0
        }
        World:set(entity, Components.DummyBehavior, dummyBehavior)
    end

    if dummyConfig.StartsBlocking then
        const guardHeld: Components.GuardHeld = {
            Wants = true
        }
        World:set(entity, Components.GuardHeld, guardHeld)
    end

    activeBySpawn[spawnPart] = dummy

    humanoid.Died:Connect(function()
        -- I think ragdolling can fire Died signal sometimes
        if humanoid.Health > 0 then return end

        task.delay(RESPAWN_DELAY, function()
            dummy:Destroy()
            activeBySpawn[spawnPart] = nil
            self:_SpawnDummy(spawnPart)
        end)
    end)
end

function DummyService:_CreateIndicator(dummy: Model, root: BasePart): BasePart

    const indicatorPart = Instance.new("Part")
    indicatorPart.Name = "Indicator"
    indicatorPart.Size = Vector3.one
    indicatorPart.Material = Enum.Material.Neon
    indicatorPart.BrickColor = BrickColor.Green()
    indicatorPart.Anchored = false
    indicatorPart.CanCollide = false
    indicatorPart.Massless = true
    indicatorPart.CanQuery = false
    indicatorPart.CanTouch = false

    indicatorPart.Position = root.Position + Vector3.new(0, INDICATOR_HEIGHT, 0)
    
    const weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = indicatorPart
    weld.Parent = indicatorPart

    indicatorPart.Parent = dummy

    return indicatorPart
end

return DummyService