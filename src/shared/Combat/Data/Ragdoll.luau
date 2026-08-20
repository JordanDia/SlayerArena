--!strict

const Ragdoll = table.freeze {

    MinDuration = 60,

    GroundTime = 20,
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