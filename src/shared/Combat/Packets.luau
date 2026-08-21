--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const ByteNet = require(ReplicatedStorage.Packages.ByteNet)

export type VfxPayload = {
    Character: Instance,
    Kind: number,
    Duration: number,
    Position: Vector3?,
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

        DashRequest = ByteNet.definePacket {
            value = ByteNet.uint8,
            reliabilityType = "reliable"
        },

        Dash = ByteNet.definePacket {
            value = ByteNet.struct { Direction = ByteNet.vec3, Speed = ByteNet.uint16, Duration = ByteNet.uint16 },
            reliabilityType = "reliable"
        },

        DoubleJumpRequest = ByteNet.definePacket {
            value = ByteNet.uint8,
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
            value = ByteNet.struct { Character = ByteNet.inst, Kind = ByteNet.uint8, Duration = ByteNet.uint16, Position = ByteNet.optional(ByteNet.vec3), },
            reliabilityType = "reliable"
        },

        BlockRequest = ByteNet.definePacket {
            value = ByteNet.bool,
            reliabilityType = "reliable"
        }
    }
end)