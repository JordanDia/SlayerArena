const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const World = require("@game/ReplicatedStorage/Shared/Combat/World")
const CharacterBindingService = require("./CharacterBindingService")

const DebugService = {}

local function WaitForEntity(player: Player): World.Entity?
    
    local elapsed = 0

    while elapsed < 5 do
        const character = player.Character
        if not character then
            elapsed += task.wait(0.1)
            continue
        end

        local entity = CharacterBindingService.GetEntity(character)
        if entity then
            return entity
        end

        elapsed += task.wait(0.1)
    end

    return nil
end

function DebugService:Start()
    if not RunService:IsStudio() then return end

    const player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
    const entity = WaitForEntity(player)

    if not entity then
        warn("[DebugService] No entity found")
        return
    end
end


return DebugService