--!strict

export type VfxKind = "Hit" | "Knockback" | "Dodge" | "SwingTrail" | "Dash" | "PerfectBlock"

-- server sends byte, client uses this map to get vfx kind
const byteMap: { VfxKind } = {

    [1] = "Hit",
    [2] = "Knockback",
    [3] = "Dodge",
    [4] = "SwingTrail",
    [5] = "Dash",
    [6] = "PerfectBlock",
}

const reverseMap: { [VfxKind]: number } = {}

for byte, vfxKind in byteMap do
    reverseMap[vfxKind] = byte
end

const prefabMap: { [VfxKind] : string } = {
    Hit = "Hit",
    Knockback = "VerticalLines",
    Dodge = "Dodge",
    SwingTrail = "SwingTrail",
    Dash = "VerticalLines",
    PerfectBlock = "PerfectBlock",
}

return table.freeze {
    ByteMap = table.freeze(byteMap),
    ReverseMap = table.freeze(reverseMap),
    PrefabMap = table.freeze(prefabMap),
}