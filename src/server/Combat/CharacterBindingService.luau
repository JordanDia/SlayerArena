--!strict

const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const CombatantFactory = require(script.Parent.CombatantFactory)
const Trove = require(ReplicatedStorage.Packages.Trove)
const World = require(ReplicatedStorage.Shared.Combat.World)
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const EntityRegistry = require(ReplicatedStorage.Shared.Combat.EntityRegistry)

const CharacterBindingService = {}

const trovesByPlayer: { [Player]: Trove.Trove } = {}
const characterTroves: { [Model] : Trove.Trove} = {}

function CharacterBindingService.GetEntity(model: Model): World.Entity?
    return EntityRegistry.Get(model)
end

local function MarkDead(character: Model)
    const entity = EntityRegistry.Get(character)
    if not entity then return end

    World:add(entity, Components.Dead)

    print(`Marking entity id { entity } as dead`)
end

local function Bind(player: Player, character: Model, characterTrove: Trove.Trove)
    const entity = CombatantFactory.Create(character)
    if not entity then return end

    World:set(entity, Components.PlayerRef, player)

    const characterRef = World:get(entity, Components.CharacterRef)
    if characterRef then
        characterTrove:Connect(characterRef.Humanoid.Died, function()
            MarkDead(character)
        end)
    end
end

function CharacterBindingService.ReapSystem(_tick: number, _delta: number)
    const entities = {}

    for entity, characterRef in World:query(Components.CharacterRef):with(Components.Dead) do
        table.insert(entities, entity)
        EntityRegistry.Unregister(characterRef.Model)
    end

    for _, entity in entities do
        print(`Reaping entity id { entity }`)
        World:delete(entity)
    end
end

function CharacterBindingService.PlayerAdded(player: Player)
    const trove = Trove.new()
    trovesByPlayer[player] = trove

    trove:Connect(player.CharacterAdded, function(character: Model)
        CharacterBindingService.CharacterAdded(player, character)
    end)

    trove:Connect(player.CharacterRemoving, function(character: Model)
        CharacterBindingService.CharacterRemoving(player, character)
    end)

    local character = player.Character
    if character then
        CharacterBindingService.CharacterAdded(player, character)
    end
end

function CharacterBindingService.PlayerRemoving(player: Player)
    const character = player.Character
    if character then
        CharacterBindingService.CharacterRemoving(player, character)
    end

    const trove = trovesByPlayer[player]
    if trove then
        trove:Destroy()
        trovesByPlayer[player] = nil
    end
end

function CharacterBindingService.CharacterAdded(player: Player, character: Model)
    const trove = trovesByPlayer[player]
    if not trove then return end

    local characterTrove = trove:Extend()
    characterTroves[character] = characterTrove

    Bind(player, character, characterTrove)
end

function CharacterBindingService.CharacterRemoving(_player: Player, character: Model)
    MarkDead(character)
    const trove = characterTroves[character]
    if trove then
        trove:Destroy()
        characterTroves[character] = nil
    end
end

function CharacterBindingService:Init()
    CombatantFactory.Init()
end

function CharacterBindingService:Start()

    Players.PlayerAdded:Connect(CharacterBindingService.PlayerAdded)
    Players.PlayerRemoving:Connect(CharacterBindingService.PlayerRemoving)

    for _, player in Players:GetPlayers() do
        CharacterBindingService.PlayerAdded(player)
    end

end



return CharacterBindingService