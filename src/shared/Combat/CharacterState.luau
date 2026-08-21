--!strict
const Components = require(script.Parent.Components)

const CharacterState = {}

const rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

const DEFAULT_GROUND_DISTANCE = 3

-- Deliberately longer than DEFAULT_GROUND_DISTANCE. An R6 root sits ~3 studs above the
-- floor (HipHeight 2 + half the root's height), so a 3 stud trace from the root centre
-- ends exactly at the surface and misses on any float error or slope - which reads a
-- character standing still as airborne. IsAirborne can afford the slack because the
-- humanoid state check below is what rejects a rising jump.
const AIRBORNE_TRACE_DISTANCE = 4.5
const GETUP_TRACE_DISTANCE = 20

function CharacterState.IsGrounded(characterRef: Components.CharacterRef, distance: number?): boolean
    const traceDistance = distance or DEFAULT_GROUND_DISTANCE

    rayParams.FilterDescendantsInstances = { characterRef.Model }
    const result = workspace:Raycast(characterRef.Root.Position, Vector3.yAxis * -traceDistance, rayParams)

    return result ~= nil
end

--[[
    Deliberately NOT the negation of IsGrounded, and the difference matters.

    The raycast alone reads a rising jump as grounded for the first stud or so: an R6 root
    sits ~3 studs up, and worse, the server's copy of a player's root position is
    replicated and interpolated, so it trails by ping. Humanoid state does not - state
    changes replicate as events, not as position.

    So this is airborne if the ray misses OR the humanoid says it is jumping or falling,
    which biases toward airborne on disagreement. That bias is the right way round for
    gating an action: eating the input and charging posture and a lock for a dash that
    never happens is far worse than letting one slip out a frame after landing.

    Callers dealing with a PlatformStanded body (anything Thrown or ragdolled) must use
    IsGrounded instead - PlatformStand kills humanoid state, so this would always say
    airborne.
]]
function CharacterState.IsAirborne(characterRef: Components.CharacterRef, distance: number?): boolean
    if not CharacterState.IsGrounded(characterRef, distance or AIRBORNE_TRACE_DISTANCE) then
        return true
    end

    const state = characterRef.Humanoid:GetState()
    return state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall
end

--[[
    A character-relative direction resolved to world space using only the character's Y
    rotation, discarding pitch and roll.

    CFrame:VectorToWorldSpace uses the full orientation, so a root that is tilted - on a
    slope, mid-getup, or left leaning by a ragdoll that PlatformStand did not fully settle -
    bends the result out of the XZ plane and skews the horizontal part too. Yaw is the only
    component that should ever matter for a ground movement direction.

    Returns a flattened unit vector, or the flattened look vector if the input is degenerate.
]]
function CharacterState.YawToWorld(characterRef: Components.CharacterRef, localDirection: Vector3): Vector3
    const look = characterRef.Root.CFrame.LookVector
    const flatLook = Vector3.new(look.X, 0, look.Z)
    const forward = if flatLook.Magnitude > 0.001 then flatLook.Unit else Vector3.zAxis * -1

    -- Right handed basis on the XZ plane: right is forward rotated -90 degrees about Y.
    const right = Vector3.new(-forward.Z, 0, forward.X)

    const world = right * localDirection.X + forward * -localDirection.Z
    if world.Magnitude < 0.001 then
        return forward
    end

    return world.Unit
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