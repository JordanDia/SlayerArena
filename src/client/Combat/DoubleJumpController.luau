--!strict
const Players = game:GetService("Players")

const Packets = require("@game/ReplicatedStorage/Shared/Combat/Packets")

const Player = Players.LocalPlayer

const DoubleJumpController = {}

function DoubleJumpController:Start()

    Packets.DoubleJump.listen(function(data: { Velocity: Vector3 })

        const character = Player.Character
        if not character then return end

        const root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if not root:IsA("BasePart") then return end

        root.AssemblyLinearVelocity = data.Velocity
    end)
end

return DoubleJumpController
