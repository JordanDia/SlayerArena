--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const FrameData = require(ReplicatedStorage.Shared.Combat.Data.FrameData)
const Reactions = require(ReplicatedStorage.Shared.Combat.Data.Reactions)

export type Skill = {
    read DisplayName: string,
    read Cooldown: number,
    read Hits: { FrameData.FrameData }
}

export type Style = {
    read DisplayName: string,
    read Color: Color3,
    read SlotOrder: { string },
    read Skills: { [string]: Skill },
}

const Swing: FrameData.SoundEntry = { Kind = "PunchSwing", Tick = 18 }

const SlashVfx: FrameData.VfxEntry = { Kind = "WaterSurfaceSlash", Tick = 20 }
const WheelVfx: FrameData.VfxEntry = { Kind = "WaterWheel", Tick = 12, Duration = 120}

const WaterSurfaceSlash: FrameData.FrameData = table.freeze {
    Startup = 20,
    Active = 13,
    Recovery = 13,

    Damage = 5,
    Hitstun = 45,
    Blockstun = 12,
    PostureDamage = 7,

    KnockbackSpeed = 0,
    KnockbackUpward = 0,
    KnockbackDuration = 0,

    Ragdoll = false,

    Range = 4,
    HitboxSize = Vector3.new(5, 6, 6),

    Hitstop = 4,

    IgnoresBlock = false,
    UsableFromBlock = false,

    ComboWindow = 60,
    JumpLockoutTicks = 10,

    Vfx = { SlashVfx },
    Sound = { Swing },

    AnimationId = "rbxassetid://95473188452901",
    Reaction = "Light" :: Reactions.ReactionKind,
}

const WaterWheel: FrameData.FrameData = table.freeze {
    Startup = 12,
    -- Matches RushDuration: a shorter active window would end the hitbox two thirds
    -- of the way through the roll and leave the rest of it harmless.
    Active = 120,
    Recovery = 20,

    Damage = 4,
    Hitstun = 20,
    Blockstun = 10,
    PostureDamage = 6,

    KnockbackSpeed = 14,
    KnockbackUpward = 0,
    KnockbackDuration = 6,

    Ragdoll = false,

    Range = 3,
    HitboxSize = Vector3.new(6, 6, 6),

    HitInterval = 12,

    Hitstop = 1,

    IgnoresBlock = false,
    UsableFromBlock = false,

    ComboWindow = 60,
    JumpLockoutTicks = 10,

    -- No FacesCamera/AimsWhileActive: those aim the character at the mouse, which
    -- curves the roll. The wheel commits to the heading it launched with.
    LocksMovement = true,

    RushTick = 0,
    RushSpeed = 20,
    RushDuration = 120,

    Vfx = { WheelVfx },
    Sound = { Swing },

    AnimationId = "rbxassetid://95473188452901",
    Reaction = "Light" :: Reactions.ReactionKind,
}


const Water: Style = {
    DisplayName = "Water Breathing",
    Color = Color3.fromRGB(255, 255, 255),

    SlotOrder = table.freeze { "WaterSurfaceSlash", "WaterWheel" },

    Skills = table.freeze {
        WaterSurfaceSlash = table.freeze {
            DisplayName = "Surface Slash",
            Cooldown = 300,
            Hits = table.freeze { WaterSurfaceSlash },
        },

        WaterWheel = {
            DisplayName = "Water Wheel",
            Cooldown = 0,
            Hits = table.freeze { WaterWheel }
        }
    }  :: { [string]: Skill}
}

return Water