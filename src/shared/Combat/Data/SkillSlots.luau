--!strict

const Abilities = require(script.Parent.Abilities)

-- placeholder for the equipped-fruit resolver: slot number to ability
const SkillSlots: { Abilities.AbilityId } = {

    [1] = "Pistol",
}

return table.freeze(SkillSlots)
