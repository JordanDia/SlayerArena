--!strict
const Air = require(script.Parent.Air)
const Crit = require(script.Parent.Crit)
const FrameData = require(script.Parent.FrameData)
const Grab = require(script.Parent.Grab)
const M1 = require(script.Parent.M1)
const Uptilt = require(script.Parent.Uptilt)
const Styles = require(script.Parent.Styles)

export type AbilityId = "M1" | "Grab" | "Uptilt" | "Air" | "Crit" | "CritEmpowered" | "WaterSurfaceSlash"

const Abilities: { [AbilityId]: { FrameData.FrameData } } = {
    M1 = M1,
    Grab = Grab,
    Uptilt = Uptilt,
    Air = Air,
    Crit = Crit.Normal,
    CritEmpowered = Crit.Empowered,

}

for id, skill in Styles.SkillRegistry do
    Abilities[id :: AbilityId] = skill.Hits
end

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
