--!strict
const Components = require(script.Parent.Components)

const CharacterState = {}

const rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

const DEFAULT_GROUND_DISTANCE = 3
const GETUP_TRACE_DISTANCE = 20

function CharacterState.IsGrounded(characterRef: Components.CharacterRef, distance: number?): boolean
    const traceDistance = distance or DEFAULT_GROUND_DISTANCE

    rayParams.FilterDescendantsInstances = { characterRef.Model }
    const result = workspace:Raycast(characterRef.Root.Position, Vector3.yAxis * -traceDistance, rayParams)

    return result ~= nil
end

function CharacterState.SnapUpright(characterRef: Components.CharacterRef, lookDirection: Vector3)
    const root = characterRef.Root

    const flatLook = Vector3.new(lookDirection.X, 0, lookDirection.Z)
    const facing = if flatLook.Magnitude > 0.001 then flatLook.Unit else Vector3.zAxis

    rayParams.FilterDescendantsInstances = { characterRef.Model }
    const result = workspace:Raycast(root.Position, Vector3.yAxis * -GETUP_TRACE_DISTANCE, rayParams)

    const standHeight = characterRef.Humanoid.HipHeight + root.Size.Y / 2
    const position = if result then result.Position + Vector3.yAxis * standHeight else root.Position

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = CFrame.lookAt(position, position + facing)

    characterRef.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
end

return CharacterState