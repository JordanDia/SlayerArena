--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const ByteNet = require(ReplicatedStorage.Packages.ByteNet)

export type VfxPayload = {
    Character: Instance,
    Kind: number,
    Duration: number,
    Position: Vector3?,
    -- world space, for effects that have to be aimed rather than just placed
    Direction: Vector3?,
}

return ByteNet.defineNamespace("combat", function()
    return {
        AttackRequest = ByteNet.definePacket {
            value = ByteNet.nothing,
            reliabilityType = "reliable"
        },

        GrabRequest = ByteNet.definePacket {
            value = ByteNet.nothing,
            reliabilityType = "reliable"
        },

        DodgeRequest = ByteNet.definePacket {
            value = ByteNet.nothing,
            reliabilityType = "reliable"
        },

        -- Kind picks the animation and must stay character-relative; Direction is the
        -- camera-relative world vector the dash actually travels along. One value
        -- cannot do both - snapping to four axes is up to 45 degrees of error.
        DashRequest = ByteNet.definePacket {
            value = ByteNet.struct { Kind = ByteNet.uint8, Direction = ByteNet.vec3 },
            reliabilityType = "reliable"
        },

        Dash = ByteNet.definePacket {
            value = ByteNet.struct { Direction = ByteNet.vec3, Speed = ByteNet.uint16, Duration = ByteNet.uint16 },
            reliabilityType = "reliable"
        },

        -- Same split as DashRequest: Kind picks the animation and stays
        -- character-relative, Direction is the camera-relative world vector travelled.
        DoubleJumpRequest = ByteNet.definePacket {
            value = ByteNet.struct { Kind = ByteNet.uint8, Direction = ByteNet.vec3 },
            reliabilityType = "reliable"
        },

        DoubleJump = ByteNet.definePacket {
            value = ByteNet.struct { Velocity = ByteNet.vec3 },
            reliabilityType = "reliable"
        },

        Getup = ByteNet.definePacket {
            value = ByteNet.nothing,
            reliabilityType = "reliable"
        },

        Knockback = ByteNet.definePacket {
            value = ByteNet.struct { Velocity = ByteNet.vec3, Duration = ByteNet.uint16 },
            reliabilityType = "reliable"
        },

        Vfx = ByteNet.definePacket {
            value = ByteNet.struct { Character = ByteNet.inst, Kind = ByteNet.uint8, Duration = ByteNet.uint16, Position = ByteNet.optional(ByteNet.vec3), Direction = ByteNet.optional(ByteNet.vec3), },
            reliabilityType = "reliable"
        },

        BlockRequest = ByteNet.definePacket {
            value = ByteNet.bool,
            reliabilityType = "reliable"
        },

        UptiltRequest = ByteNet.definePacket {
            value = ByteNet.bool,
            reliabilityType = "reliable"
        }
    }
end)