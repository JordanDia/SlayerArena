--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Abilities = require(ReplicatedStorage.Shared.Combat.Data.Abilities)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const World = require(ReplicatedStorage.Shared.Combat.World)

--[[
    A sustained drive, as opposed to RecoilSystem's single impulse: the client holds a
    LinearVelocity for the duration instead of applying one ApplyImpulse that bleeds
    off against friction in a few frames.

    No direction is sent. The client re-reads the character's facing every frame, so
    the rush steers with the aim rather than committing to a heading at launch. That
    is also why RushDuration is the client's business and this system fires once.
]]
const function RushSystem(tick: number, _delta: number)
    for entity, activeAttack in World:query(Components.ActiveAttack):without(Components.Dead) do
        if activeAttack.FiredRush then continue end

        const frameData = Abilities.Get(activeAttack.Ability, activeAttack.HitIndex)
        if not frameData.RushTick then continue end

        const elapsed = tick - activeAttack.StartedAt - activeAttack.PausedTicks
        if elapsed < frameData.RushTick then continue end

        activeAttack.FiredRush = true

        const playerRef = World:get(entity, Components.PlayerRef)
        if not playerRef then continue end

        Packets.Rush.sendTo({
            Speed = frameData.RushSpeed or 0,
            Duration = frameData.RushDuration or 0,
        }, playerRef)
    end
end

return RushSystem
