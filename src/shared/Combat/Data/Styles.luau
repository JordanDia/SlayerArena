--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Water = require(ReplicatedStorage.Shared.Combat.Data.BreathingStyles.Water)

export type StyleId = "Water" | "Thunder"

const Styles: { [StyleId]: Water.Style } = {
    Water = Water
}

const SkillRegistry: { [string]: Water.Skill } = {}
for _, style in Styles do
    for id, skill in style.Skills do
        if SkillRegistry[id] then
            error(`Duplicate skill id: {id}`)
        end
        SkillRegistry[id] = skill
    end
end

-- Takes a plain string: the id arrives from EquippedStyle and from the network,
-- neither of which can carry the literal union. The lookup itself is the validation.
const function Get(styleId: string): Water.Style?
    return Styles[styleId :: StyleId]
end

const function SlotToAbility(styleId: string, slot: number): string?
    const style = Get(styleId)
    if not style then return nil end

    return style.SlotOrder[slot]
end

return table.freeze {
    Styles = Styles,
    SkillRegistry = SkillRegistry,
    Get = Get,
    SlotToAbility = SlotToAbility
}
