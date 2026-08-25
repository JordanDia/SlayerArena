--!strict

const CooldownDurations = {
    AirJump = 20,
    Dash = 45,
    Feint = 180,
    Crit = 120,
}

const function Get(id: CooldownId): number
    return (CooldownDurations :: { [CooldownId]: number })[id]
end

-- This seals off indexing, so we must use Get function
export type CooldownId = keyof<typeof(CooldownDurations)>

return table.freeze {
    CooldownDurations = CooldownDurations,
    Get = Get,
}