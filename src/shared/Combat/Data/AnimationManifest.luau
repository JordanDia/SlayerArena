--!strict
const Abilities = require(script.Parent.Abilities)
const Dodge = require(script.Parent.Dodge)
const Reactions = require(script.Parent.Reactions)
const States = require(script.Parent.States)

const seen: { [string]: boolean } = {}
const ids: { {Id: string, Looped: boolean, Priority: Enum.AnimationPriority} } = {}

local function Add(id: string, looped: boolean, priority: Enum.AnimationPriority)
    if id == "" then return end
    if seen[id] then return end
    seen[id] = true

    table.insert(ids, {
        Id = id,
        Looped = looped,
        Priority = priority,
    })
end

for _, ability in Abilities.Abilities do
    for _, frameData in ability do
        Add(frameData.AnimationId, false, Enum.AnimationPriority.Action)
    end
    
end

for _, animationId in Reactions do
    Add(animationId, false, Enum.AnimationPriority.Action2)
end

for _, state in States do
    Add(state.Id, state.Looped, state.Priority)
end

Add(Dodge.AnimationId, false, Enum.AnimationPriority.Action)

return table.freeze(ids)