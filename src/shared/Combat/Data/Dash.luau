--!strict

export type DashKind = "Forward" | "Back" | "Left" | "Right"

const byteMap: { DashKind } = {
    [1] = "Forward",
    [2] = "Back",
    [3] = "Left",
    [4] = "Right",
}

const reverseMap: { [DashKind]: number } = {}

for byte, dashKind in byteMap do
    reverseMap[dashKind] = byte
end

const animationMap: { [DashKind]: string } = {
    Forward = "rbxassetid://130155103531964",
    Back = "rbxassetid://122883802500599",
    Left = "rbxassetid://113597625886503",
    Right = "rbxassetid://116283214693382",
}

const directionMap: { [DashKind]: Vector3 } = {
    Forward = Vector3.new(0, 0, -1),
    Back = Vector3.new(0, 0, 1),
    Left = Vector3.new(-1, 0, 0),
    Right = Vector3.new(1, 0, 0),
}

return table.freeze {

    Duration = 8,
    Speed = 90,

    GhostCount = 3,
    GhostLifetime = 0.3,
    GhostTransparency = 0.5,
    GhostColor = Color3.fromRGB(0, 0, 0),

    ByteMap = table.freeze(byteMap),
    ReverseMap = table.freeze(reverseMap),
    DirectionMap = table.freeze(directionMap),
    AnimationMap = table.freeze(animationMap),
}
