--!strict

export type VfxKind = "Hit" | "Knockback" | "Dodge" | "SwingTrail" | "Dash" | "PerfectBlock" | "Geppo" | "GroundSlam" | "Block" | "BlockBreak" | "PistolArm"

-- server sends byte, client uses this map to get vfx kind
const byteMap: { VfxKind } = {

    [1] = "Hit",
    [2] = "Knockback",
    [3] = "Dodge",
    [4] = "SwingTrail",
    [5] = "Dash",
    [6] = "PerfectBlock",
    [7] = "Geppo",
    [8] = "GroundSlam",
    [9] = "Block",
    [10] = "BlockBreak",
    [11] = "PistolArm",
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
    Geppo = "Geppo",
    Block = "Block",
    BlockBreak = "BlockBreak",
    PistolArm = "GomuPistol",
}

return table.freeze {
    ByteMap = table.freeze(byteMap),
    ReverseMap = table.freeze(reverseMap),
    PrefabMap = table.freeze(prefabMap),
}