--!strict
const FrameData = require(script.Parent.FrameData)
const Grab = require(script.Parent.Grab)
const M1 = require(script.Parent.M1)

export type AbilityId = "M1" | "Grab"

const Abilities: { [AbilityId]: { FrameData.FrameData } } = {
    M1 = M1,
    Grab = Grab,
}

const function Get(ability: AbilityId, hitIndex: number)
    return Abilities[ability][hitIndex]
end

const function Length(ability: AbilityId)
    return #Abilities[ability]
end

return table.freeze {
    Abilities = Abilities,
    Get = Get,
    Length = Length,
}