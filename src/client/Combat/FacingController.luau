--!strict
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const UserInputService = game:GetService("UserInputService")

const Packets = require(ReplicatedStorage.Shared.Combat.Packets)

const TURN_SPEED = 200
const AIM_DISTANCE = 500

const player = Players.LocalPlayer

local connection: RBXScriptConnection?
local autoRotate = true
local pin: AlignPosition?
local pinAttachment: Attachment?
local aim: AlignOrientation?
local aimAttachment: Attachment?

const aimParams = RaycastParams.new()
aimParams.FilterType = Enum.RaycastFilterType.Exclude
aimParams.IgnoreWater = true

const FacingController = {}

const function GetMouseTarget(character: Model): Vector3?
    const camera = workspace.CurrentCamera
    if not camera then return nil end

    const location = UserInputService:GetMouseLocation()
    const ray = camera:ViewportPointToRay(location.X, location.Y)

    aimParams.FilterDescendantsInstances = { character }

    const result = workspace:Raycast(ray.Origin, ray.Direction * AIM_DISTANCE, aimParams)
    if result then return result.Position end

    return ray.Origin + ray.Direction * AIM_DISTANCE
end

-- Stops following the mouse but leaves the constraint holding whatever it was aimed at.
const function StopAiming()
    if connection then
        connection:Disconnect()
        connection = nil
    end
end

const function Release()
    StopAiming()

    if aim then
        aim:Destroy()
        aim = nil
    end

    if aimAttachment then
        aimAttachment:Destroy()
        aimAttachment = nil
    end

    if pin then
        pin:Destroy()
        pin = nil
    end

    if pinAttachment then
        pinAttachment:Destroy()
        pinAttachment = nil
    end

    const character = player.Character
    if not character then return end

    const humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    humanoid.PlatformStand = false
    humanoid.AutoRotate = autoRotate

    -- Dropping PlatformStand lets the state machine pick the next state itself, and it
    -- reaches for FallingDown, which is the trip. Naming the state explicitly skips it:
    -- Freefall settles into Landed on its own once the character touches ground.
    if humanoid.FloorMaterial == Enum.Material.Air then
        humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
    else
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
end

const function StartAiming()
    StopAiming()

    const character = player.Character
    if not character then return end

    const root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if not root:IsA("BasePart") then return end

    const humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    autoRotate = humanoid.AutoRotate
    humanoid.AutoRotate = false

    if not aim then
        const attachment = Instance.new("Attachment")
        attachment.Parent = root
        aimAttachment = attachment

        const orientation = Instance.new("AlignOrientation")
        orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
        orientation.Attachment0 = attachment
        orientation.RigidityEnabled = false
        orientation.MaxTorque = math.huge
        orientation.MaxAngularVelocity = math.huge
        orientation.Responsiveness = TURN_SPEED
        orientation.CFrame = root.CFrame.Rotation
        orientation.Parent = root
        aim = orientation
    end

    const orientation = aim
    if not orientation then return end

    connection = RunService.RenderStepped:Connect(function(_deltaTime: number)
        if not root.Parent then
            Release()
            return
        end

        const target = GetMouseTarget(character)
        if not target then return end

        const offset = target - root.Position
        if offset.Magnitude < 0.001 then return end

        orientation.CFrame = CFrame.lookAt(Vector3.zero, offset.Unit)
    end)
end

const function SetFrozen(freeze: boolean)
    if not freeze then
        Release()
        return
    end

    const character = player.Character
    if not character then return end

    const root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if not root:IsA("BasePart") then return end

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    const humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
    end

    const attachment = Instance.new("Attachment")
    attachment.Parent = root
    pinAttachment = attachment

    const align = Instance.new("AlignPosition")
    align.Mode = Enum.PositionAlignmentMode.OneAttachment
    align.Attachment0 = attachment
    align.Position = root.Position
    align.RigidityEnabled = true
    align.Parent = root
    pin = align
end

-- Called the moment the input is released, so the aim is committed locally instead of a
-- round trip later. Without this the character keeps turning for one ping after release
-- and the arm no longer lines up with the hitbox the server is stepping.
--
-- Stopping the mouse follow is not enough on its own: the constraint eases toward its
-- goal, so the character keeps drifting for a few frames. The committed rotation is
-- snapped onto the root and then held rigidly, which also puts it back if anything
-- turned it in the meantime.
function FacingController:CommitAim()
    const orientation = aim
    if not orientation then return end

    StopAiming()

    const committed = orientation.CFrame.Rotation
    orientation.CFrame = committed
    orientation.Responsiveness = math.huge
    orientation.RigidityEnabled = true

    const character = player.Character
    if not character then return end

    const root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if not root:IsA("BasePart") then return end

    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = CFrame.new(root.Position) * committed
end

function FacingController:Start()
    Packets.ChargeFreeze.listen(function(freeze: boolean)
        SetFrozen(freeze)
    end)

    Packets.FacingLock.listen(function(locked: boolean)
        if locked then
            StartAiming()
        elseif pin then
            StopAiming()
        else
            Release()
        end
    end)

    player.CharacterRemoving:Connect(Release)
end

return FacingController
