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

export type SoundPayload = {
    Character: Instance,
    Kind: number,
}

return ByteNet.defineNamespace("combat", function()
    return {
        AttackRequest = ByteNet.definePacket {
            value = ByteNet.nothing,
        },

        GrabRequest = ByteNet.definePacket {
            value = ByteNet.nothing,
        },

        DashRequest = ByteNet.definePacket {
            value = ByteNet.struct { Kind = ByteNet.uint8, Direction = ByteNet.vec3 },
        },

        Dash = ByteNet.definePacket {
            value = ByteNet.struct { Direction = ByteNet.vec3, Speed = ByteNet.uint16, Duration = ByteNet.uint16 },
        },

        SprintToggle = ByteNet.definePacket {
            value = ByteNet.nothing,
        },

        -- Same split as DashRequest: Kind picks the animation and stays
        -- character-relative, Direction is the camera-relative world vector travelled.
        DoubleJumpRequest = ByteNet.definePacket {
            value = ByteNet.struct { Kind = ByteNet.uint8, Direction = ByteNet.vec3 },
        },

        DoubleJump = ByteNet.definePacket {
            value = ByteNet.struct { Velocity = ByteNet.vec3 },
        },

        Getup = ByteNet.definePacket {
            value = ByteNet.nothing,
        },

        Knockback = ByteNet.definePacket {
            value = ByteNet.struct { Velocity = ByteNet.vec3, Duration = ByteNet.uint16 },
        },

        Vfx = ByteNet.definePacket {
            value = ByteNet.struct { Character = ByteNet.inst, Kind = ByteNet.uint8, Duration = ByteNet.uint16, Position = ByteNet.optional(ByteNet.vec3), Direction = ByteNet.optional(ByteNet.vec3), },
        },

        Sound = ByteNet.definePacket {
            value = ByteNet.struct { Character = ByteNet.inst, Kind = ByteNet.uint8 },
        },

        SkillRequest = ByteNet.definePacket {
            value = ByteNet.uint8,
        },

        ChargeFreeze = ByteNet.definePacket {
            value = ByteNet.bool,
        },

        FacingLock = ByteNet.definePacket {
            value = ByteNet.bool,
        },

        SkillHoldRequest = ByteNet.definePacket {
            value = ByteNet.bool,
        },

        GuardRequest = ByteNet.definePacket {
            value = ByteNet.bool,
        },

        CritRequest = ByteNet.definePacket {
            value = ByteNet.bool,
        },

        UptiltRequest = ByteNet.definePacket {
            value = ByteNet.bool,
        },

        Rush = ByteNet.definePacket {
            value = ByteNet.struct { Speed = ByteNet.uint16, Duration = ByteNet.uint16 }
        },


        StyleRequest = ByteNet.definePacket {
            value = ByteNet.string
        }
    }
end)