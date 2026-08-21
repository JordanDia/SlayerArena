--!strict
const Players = game:GetService("Players")

const Packets = require("@game/ReplicatedStorage/Shared/Combat/Packets")

const Player = Players.LocalPlayer

const KnockbackController = {}

function KnockbackController:Start()

    Packets.Knockback.listen(function(data: { Velocity: Vector3, Duration: number })

        const character = Player.Character
        if not character then return end

        const root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if not root:IsA("BasePart") then return end

        root:ApplyImpulse(data.Velocity * root.AssemblyMass)
    end)
end

return KnockbackController
