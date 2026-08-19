--!strict
const Players = game:GetService("Players")

const Packets = require("@game/ReplicatedStorage/Shared/Combat/Packets")
const Scheduler = require("@game/ReplicatedStorage/Shared/Combat/Scheduler")

const Player = Players.LocalPlayer

const KnockbackController = {}

function KnockbackController:Start()

    Packets.Knockback.listen(function(data: { Velocity: Vector3, Duration: number})

        const character = Player.Character
        if not character then return end
        
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        const rootAttachment = root:FindFirstChild("RootAttachment") :: Attachment?
        if not rootAttachment then return end

        const linearVel = Instance.new("LinearVelocity")
        linearVel.RelativeTo = Enum.ActuatorRelativeTo.World
        linearVel.VectorVelocity = data.Velocity
        linearVel.MaxForce = math.huge

        linearVel.Attachment0 = rootAttachment
        linearVel.Parent = character

        task.delay(Scheduler.TicksToSeconds(data.Duration), function()
            linearVel:Destroy()
        end)

    end)
end

return KnockbackController