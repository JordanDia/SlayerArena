--!strict

const Headroom = {}

--[[
    How far `root` can travel along `travel` before it hits geometry, capped at the
    magnitude of `travel` itself. Returns a distance, not a position.

    Blockcast rather than Raycast: a ray is a line and a character is a box, so a
    beam clipping a shoulder would be missed entirely and the character would end up
    inside it. The cast CFrame is deliberately axis-aligned rather than the root's
    own CFrame, so the box does not spin with the character - the same spot under the
    same beam must clamp the same way regardless of which way they happen to face.
]]
function Headroom.Resolve(origin: Vector3, size: Vector3, travel: Vector3, margin: number, ignore: { Instance }): number
    const desired = travel.Magnitude
    if desired < 0.001 then
        return 0
    end

    const params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignore
    params.IgnoreWater = true

    const result = workspace:Blockcast(CFrame.new(origin), size, travel, params)
    if not result then
        return desired
    end

    return math.clamp(result.Distance - margin, 0, desired)
end

return table.freeze(Headroom)
