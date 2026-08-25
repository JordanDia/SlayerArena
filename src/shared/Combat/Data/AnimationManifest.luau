--!strict
const Abilities = require(script.Parent.Abilities)
const Dash = require(script.Parent.Dash)
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
        if frameData.LoopAnimationId then
            Add(frameData.LoopAnimationId, true, Enum.AnimationPriority.Action)
        end
    end
    
end

for _, reaction in Reactions do
    Add(reaction.Id, reaction.Looped, Enum.AnimationPriority.Action2)
end

for _, state in States do
    Add(state.Id, state.Looped, state.Priority)
end

for _, animationId in Dash.AnimationMap do
    Add(animationId, true, Enum.AnimationPriority.Action)
end


return table.freeze(ids)