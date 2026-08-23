--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Abilities = require(ReplicatedStorage.Shared.Combat.Data.Abilities)
const SoundManifest = require(ReplicatedStorage.Shared.Combat.Data.SoundManifest)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function AttackSoundSystem(tick: number, _delta: number)
    for _entity, activeAttack, characterRef in World:query(Components.ActiveAttack, Components.CharacterRef):without(Components.Dead) do
        -- get frame data
        
        const frameData = Abilities.Get(activeAttack.Ability, activeAttack.HitIndex)
        if not frameData.Sound then continue end

        const elapsed = tick - activeAttack.StartedAt - activeAttack.PausedTicks
        for index, entry in frameData.Sound do
            if activeAttack.FiredSounds[index] then continue end
            if elapsed < entry.Tick then continue end

            activeAttack.FiredSounds[index] = true

            Packets.Sound.sendToAll({
                Character = characterRef.Model,
                Kind = SoundManifest.ReverseMap[entry.Kind],
            })
        end
    end
end

return AttackSoundSystem