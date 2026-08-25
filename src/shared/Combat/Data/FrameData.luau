--!strict

const Reactions = require(script.Parent.Reactions)
const SoundManifest = require(script.Parent.SoundManifest)
const VfxManifest = require(script.Parent.VfxManifest)

export type VfxEntry = {
    read Kind: VfxManifest.VfxKind,
    read Tick: number,
    read Duration: number?
}

export type SoundEntry = {
    read Kind: SoundManifest.SoundKind,
    read Tick: number,
}

-- Timing is in ticks, 60 Hz
export type FrameData = {
    read Startup: number,
    read Active: number,
    read Recovery: number,

    read Damage: number,
    read Hitstun: number,
    read Blockstun: number,
    read PostureDamage: number,

    read KnockbackSpeed: number,
    read KnockbackUpward: number,
    read KnockbackDuration: number,

    read Feintable: boolean?,

    read Ragdoll: boolean,

    read Range: number,
    read HitboxSize: Vector3,
    read HitInterval: number?,

    read Hitstop: number,

    read IgnoresBlock: boolean,
    read UsableFromBlock: boolean,

    read ComboWindow: number,
    read JumpLockoutTicks: number,

    read AnimationId: string,
    read Reaction: Reactions.ReactionKind,

    read Vfx: { VfxEntry }?,

    -- optional, presence means the hitbox travels outward instead of sitting at Range
    read HitboxSpeed: number?,
    read HitboxMaxRange: number?,

    -- optional, anchors the attacker for the whole attack so gravity does not apply
    read FreezesInPlace: boolean?,

    -- optional, roots the attacker and turns them with the camera for the whole attack
    read LocksMovement: boolean?,
    read FacesCamera: boolean?,

    -- optional, holds the last tick of startup until the input is released
    read Chargeable: boolean?,
    read MaxChargeTicks: number?,
    read AimsWhileActive: boolean?,

    -- optional, self knockback; RecoilTick is measured from the start of the attack
    read RecoilTick: number?,
    read RecoilSpeed: number?,
    read RecoilUpward: number?,
    read RecoilDuration: number?,
    read Sound: { SoundEntry }?,

    -- how long does player float in the air for uptilts?
    read SuspendTicks: number?,

    -- ends an in-progress suspend on contact
    read EndsSuspend: boolean?,

    -- how long is the entity pinned on the ground after a downslam requires Ragdoll
    read PinTicks: number?,

    -- optional, used for grabbing
    read ReleaseTick: number?,
    read LoopAnimationId: string?
}

return {}