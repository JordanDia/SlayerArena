--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const ByteNet = require(ReplicatedStorage.Packages.ByteNet)

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

        Knockback = ByteNet.definePacket {
            value = ByteNet.struct { Velocity = ByteNet.vec3, Duration = ByteNet.uint16 },
            reliabilityType = "reliable"
        },

        Vfx = ByteNet.definePacket {
            value = ByteNet.struct { Character = ByteNet.inst, Kind = ByteNet.uint8, Duration = ByteNet.uint16, },
            reliabilityType = "reliable"
        },

        BlockRequest = ByteNet.definePacket {
            value = ByteNet.bool,
            reliabilityType = "reliable"
        }
    }
end)