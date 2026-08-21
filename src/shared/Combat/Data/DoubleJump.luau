--!strict

const Dash = require(script.Parent.Dash)

export type DoubleJumpKind = "Neutral" | "Forward" | "Back" | "Left" | "Right"

const byteMap: { DoubleJumpKind } = {
    [1] = "Neutral",
    [2] = "Forward",
    [3] = "Back",
    [4] = "Left",
    [5] = "Right",
}

const reverseMap: { [DoubleJumpKind]: number } = {}

for byte, doubleJumpKind in byteMap do
    reverseMap[doubleJumpKind] = byte
end

const directionMap: { [DoubleJumpKind]: Vector3 } = {
    Neutral = Vector3.zero,
    Forward = Vector3.new(0, 0, -1),
    Back = Vector3.new(0, 0, 1),
    Left = Vector3.new(-1, 0, 0),
    Right = Vector3.new(1, 0, 0),
}

const animationMap: { [DoubleJumpKind]: string } = {
    Neutral = "",
    Forward = Dash.AnimationMap.Forward,
    Back = Dash.AnimationMap.Back,
    Left = Dash.AnimationMap.Left,
    Right = Dash.AnimationMap.Right,
}

return table.freeze {

    Speed = 60,
    NeutralSpeed = 85,

    ByteMap = table.freeze(byteMap),
    ReverseMap = table.freeze(reverseMap),
    DirectionMap = table.freeze(directionMap),
    AnimationMap = table.freeze(animationMap),
}
