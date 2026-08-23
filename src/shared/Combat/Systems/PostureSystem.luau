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
        const blocking = World:has(entity, Components.Blocking)
        if blocking then
            posture.Current = math.max(posture.Current - Block.DrainPerTick, 0)
            posture.LastDamagedTick = tick

            if posture.Current <= 0 then
                World:remove(entity, Components.Blocking)
                World:remove(entity, Components.Blockstun)

                const stunned: Components.Stunned = {
                    StartedAt = tick,
                    EndsAt = tick + Block.GuardBreakStun,
                    Reaction = "GuardBreak"
                }
                World:set(entity, Components.Stunned, stunned)

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

            end

        else
            if tick >= posture.LastDamagedTick + Block.RegenDelay then
                posture.Current = math.min(posture.Current + Block.RegenPerTick, posture.Max)
            end
        end
    end
end

return PostureSystem
