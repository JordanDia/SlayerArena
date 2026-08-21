--!strict

const Ragdoll = table.freeze {

    MinDuration = 60,

    GroundTime = 20,

    -- A ground pin waits for the body to actually land before it holds anything.
    -- PinSettleDistance is how close below the root counts as landed, PinGiveUp is
    -- the safety deadline for a body that never lands (knocked off the map, caught
    -- on geometry) so the component cannot linger forever.
    PinSettleDistance = 4,

    -- How high above the ground the root is held. A ragdoll lies down, so this is far
    -- lower than the ~3 studs a standing HumanoidRootPart sits at.
    PinRestHeight = 0,
    PinGiveUp = 180,
    PinCastSize = Vector3.new(2, 1, 2),
    PinMaxForce = 100000,
    PinResponsiveness = 200,

    GetupDuration = 30,
    SettledSpeed = 2,

    UpperAngle = 45,
    TwistLowerAngle = -45,
    TwistUpperAngle = 45,

    JointNames = table.freeze {
        "Neck",
        "Right Shoulder",
        "Left Shoulder",
        "Right Hip",
        "Left Hip"
    }

}

return Ragdoll