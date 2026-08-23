--!strict

export type Profile = {
    read StartRange: number,
    read MaxRange: number,
    read ExtendTicks: number,
    read ReturnTicks: number,
    read Thickness: number,
}

const Pistol: Profile = table.freeze {
    StartRange = 3,
    MaxRange = 60,
    ExtendTicks = 14,
    ReturnTicks = 12,
    Thickness = 0.9,
}

return table.freeze {
    Pistol = Pistol,
}
