--!strict
const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const Packets = require("@game/ReplicatedStorage/Shared/Combat/Packets")
const Scheduler = require("@game/ReplicatedStorage/Shared/Combat/Scheduler")

const Player = Players.LocalPlayer

local activeDash: (() -> ())? = nil

const DashController = {}

function DashController:Start()

    Packets.Dash.listen(function(data: { Direction: Vector3, Speed: number, Duration: number })

        const character = Player.Character
        if not character then return end

        const root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if not root:IsA("BasePart") then return end

        const rootAttachment = root:FindFirstChild("RootAttachment") :: Attachment?
        if not rootAttachment then return end

        if activeDash then
            activeDash()
        end

        -- Already world space and flattened by DashSystem. Converting again would
        -- rotate it by the character's facing a second time.
        const velocity = if data.Direction.Magnitude > 0.001
            then data.Direction.Unit * data.Speed
            else Vector3.zero

        const linearVel = Instance.new("LinearVelocity")
        linearVel.RelativeTo = Enum.ActuatorRelativeTo.World
        linearVel.VectorVelocity = velocity
        linearVel.MaxForce = math.huge
        linearVel.Attachment0 = rootAttachment
        linearVel.Parent = character

        local stopped = false
        local connection: RBXScriptConnection? = nil

        const function Stop()
            if stopped then return end
            stopped = true

            if connection then
                connection:Disconnect()
            end

            linearVel:Destroy()

            if activeDash == Stop then
                activeDash = nil
            end
        end

        connection = RunService.RenderStepped:Connect(function(_deltaTime: number)
            if not root.Parent then
                Stop()
                return
            end
        end)

        activeDash = Stop

        task.delay(Scheduler.TicksToSeconds(data.Duration), Stop)
    end)
end

return DashController
