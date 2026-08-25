--!strict
const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const Packets = require("@game/ReplicatedStorage/Shared/Combat/Packets")
const Scheduler = require("@game/ReplicatedStorage/Shared/Combat/Scheduler")

const Player = Players.LocalPlayer

-- Its own slot rather than sharing DashController's: a dash mid-rush should not
-- silently tear down the rush, and vice versa.
local activeRush: (() -> ())? = nil

const RushController = {}

function RushController:Start()

    Packets.Rush.listen(function(data: { Speed: number, Duration: number })

        const character = Player.Character
        if not character then return end

        const root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if not root:IsA("BasePart") then return end

        const rootAttachment = root:FindFirstChild("RootAttachment") :: Attachment?
        if not rootAttachment then return end

        if activeRush then
            activeRush()
        end

        const linearVel = Instance.new("LinearVelocity")
        linearVel.RelativeTo = Enum.ActuatorRelativeTo.World
        linearVel.VectorVelocity = Vector3.zero
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

            if activeRush == Stop then
                activeRush = nil
            end
        end

        connection = RunService.RenderStepped:Connect(function(_deltaTime: number)
            if not root.Parent then
                Stop()
                return
            end

            -- Re-read every frame so the roll follows however the character is turned -
            -- shift lock, or anything else that rotates the root. Deliberately NOT the
            -- mouse: FacesCamera/AimsWhileActive are off for this move, so the only
            -- rotation source is the player turning themselves.
            const look = root.CFrame.LookVector
            const flat = Vector3.new(look.X, 0, look.Z)
            if flat.Magnitude < 0.001 then return end

            -- Carrying the character's own vertical velocity instead of zeroing it
            -- keeps gravity accumulating, so rolling off a ledge drops you. Dash gets
            -- away with a flat vector only because it lasts eight ticks.
            linearVel.VectorVelocity = flat.Unit * data.Speed
                + Vector3.yAxis * root.AssemblyLinearVelocity.Y
        end)

        activeRush = Stop

        task.delay(Scheduler.TicksToSeconds(data.Duration), Stop)
    end)
end

return RushController
