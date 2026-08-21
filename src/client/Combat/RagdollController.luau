--!strict
const Players = game:GetService("Players")

const CharacterState = require("@game/ReplicatedStorage/Shared/Combat/CharacterState")
const Packets = require("@game/ReplicatedStorage/Shared/Combat/Packets")

const Player = Players.LocalPlayer

const RagdollController = {}

function RagdollController:Start()

    Packets.Getup.listen(function(_data: nil)

        const character = Player.Character
        if not character then return end

        const humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        const root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if not root:IsA("BasePart") then return end

        const camera = workspace.CurrentCamera
        if not camera then return end

        CharacterState.SnapUpright({
            Model = character,
            Humanoid = humanoid,
            Root = root,
        }, camera.CFrame.LookVector)
    end)
end

return RagdollController
