--!strict

export type VfxKind = "Hit" | "Knockback" | "SwingTrail" | "Dash" |
"PerfectBlock" | "Geppo" | "GroundSlam" | "Block" | "BlockBreak"

-- server sends byte, client uses this map to get vfx kind
const byteMap: { VfxKind } = {

    [1] = "Hit",
    [2] = "Knockback",
    [3] = "SwingTrail",
    [4] = "Dash",
    [5] = "PerfectBlock",
    [6] = "Geppo",
    [7] = "GroundSlam",
    [8] = "Block",
    [9] = "BlockBreak",
}

const reverseMap: { [VfxKind]: number } = {}

for byte, vfxKind in byteMap do
    reverseMap[vfxKind] = byte
end

const prefabMap: { [VfxKind] : string } = {
    Hit = "Hit",
    Knockback = "VerticalLines",
    SwingTrail = "SwingTrail",
    Dash = "VerticalLines",
    PerfectBlock = "PerfectBlock",
    Geppo = "Geppo",
    Block = "Block",
    BlockBreak = "BlockBreak",
}

return table.freeze {
    ByteMap = table.freeze(byteMap),
    ReverseMap = table.freeze(reverseMap),
    PrefabMap = table.freeze(prefabMap),
}