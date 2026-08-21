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

        -- Zero first so a geppo never inherits the previous one. Assigning linear
        -- velocity already replaces it, but angular does not come along for the ride,
        -- and a body still spinning from a ragdoll or a slam carries that through.
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        root.AssemblyLinearVelocity = data.Velocity
    end)
end

return DoubleJumpController
