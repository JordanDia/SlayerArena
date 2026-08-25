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

-- See Dash.luau: an annotated table literal does not carry its element type into
-- generic iteration, so doubleJumpKind reads as string without the cast.
for byte, doubleJumpKind in byteMap do
    reverseMap[doubleJumpKind :: DoubleJumpKind] = byte
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
    Forward = Dash.AnimationMap["Forward" :: Dash.DashKind],
    Back = Dash.AnimationMap["Back" :: Dash.DashKind],
    Left = Dash.AnimationMap["Left" :: Dash.DashKind],
    Right = Dash.AnimationMap["Right" :: Dash.DashKind],
}

return table.freeze {

    Speed = 45,
    NeutralSpeed = 85,

    -- Degrees above horizontal for a directional air jump. Speed stays the vertical
    -- component, so lowering this lengthens the arc without lowering it. 45 reproduces
    -- the old equal-parts behaviour exactly.
    Angle = 30,

    ByteMap = table.freeze(byteMap),
    ReverseMap = table.freeze(reverseMap),
    DirectionMap = table.freeze(directionMap),
    AnimationMap = table.freeze(animationMap),
}
