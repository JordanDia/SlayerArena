--!strict

export type SoundKind = "PunchSwing" | "PunchHit" | "Geppo" | "GroundSlam" | "Dash" | "BlockHit" | "BlockBreak" | "PerfectBlock" | "GomuPistolCharge"

-- append only, never reorder: the byte is the wire format
const byteMap: { SoundKind } = {

    [1] = "PunchSwing",
    [2] = "PunchHit",
    [3] = "Geppo",
    [4] = "GroundSlam",
    [5] = "Dash",
    [6] = "BlockHit",
    [7] = "BlockBreak",
    [8] = "PerfectBlock",
    [9] = "GomuPistolCharge"
}

const reverseMap: { [SoundKind]: number } = {}

for byte, soundKind in byteMap do
    reverseMap[soundKind] = byte
end

return table.freeze {
    ByteMap = table.freeze(byteMap),
    ReverseMap = table.freeze(reverseMap),
}
