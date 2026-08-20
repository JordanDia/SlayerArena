--!strict
const Components = require(script.Parent.Components)

const CharacterState = {}

const rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

const DEFAULT_GROUND_DISTANCE = 3

function CharacterState.IsGrounded(characterRef: Components.CharacterRef, distance: number?): boolean
    const traceDistance = distance or DEFAULT_GROUND_DISTANCE

    rayParams.FilterDescendantsInstances = { characterRef.Model }
    const result = workspace:Raycast(characterRef.Root.Position, Vector3.yAxis * -traceDistance, rayParams)

    return result ~= nil
end

return CharacterState