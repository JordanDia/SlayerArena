--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Block = require(ReplicatedStorage.Shared.Combat.Data.Block)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const SoundManifest = require(ReplicatedStorage.Shared.Combat.Data.SoundManifest)
const VfxManifest = require(ReplicatedStorage.Shared.Combat.Data.VfxManifest)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function PostureSystem(tick: number, _delta: number)
    for entity, posture in World:query(Components.Posture):without(Components.Dead) do
        if posture.Current >= posture.Max then
            World:remove(entity, Components.Blocking)
            World:remove(entity, Components.Blockstun)
            World:remove(entity, Components.Parrying)

            const stunned: Components.Stunned = {
                StartedAt = tick,
                EndsAt = tick + Block.GuardBreakStun,
                Reaction = "GuardBreak"
            }
            World:set(entity, Components.Stunned, stunned)


            -- Reset, or we re-break every tick for the whole stun
            posture.Current = 0
            posture.LastDamagedTick = tick

            const characterRef = World:get(entity, Components.CharacterRef)
            if characterRef then
                Packets.Vfx.sendToAll({
                    Character = characterRef.Model,
                    Kind = VfxManifest.ReverseMap.BlockBreak,
                    Duration = 0,
                    Position = characterRef.Root.Position,
                })

                Packets.Sound.sendToAll({
                    Character = characterRef.Model,
                    Kind = SoundManifest.ReverseMap.BlockBreak,
                })
            end
        elseif tick >= posture.LastDamagedTick + Block.DecayDelay then
            posture.Current = math.max(posture.Current - Block.DecayPerTick, 0)
        end
    end
end

return PostureSystem
