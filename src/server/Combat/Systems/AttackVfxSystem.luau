--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Abilities = require(ReplicatedStorage.Shared.Combat.Data.Abilities)
const VfxManifest = require(ReplicatedStorage.Shared.Combat.Data.VfxManifest)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function AttackVfxSystem(tick: number, _delta: number)
    for _entity, activeAttack, characterRef in World:query(Components.ActiveAttack, Components.CharacterRef):without(Components.Dead) do
        const frameData = Abilities.Get(activeAttack.Ability, activeAttack.HitIndex)
        
        if not frameData.Vfx then continue end

        const elapsed = tick - activeAttack.StartedAt - activeAttack.PausedTicks
        for index, entry in frameData.Vfx do
            if activeAttack.FiredVfx[index] then continue end
            if elapsed < entry.Tick then continue end
            activeAttack.FiredVfx[index] = true

            Packets.Vfx.sendToAll({
                Character = characterRef.Model,
                Kind = VfxManifest.ReverseMap[entry.Kind],
                Duration = entry.Duration or 0,
            })
        end
        
        
    end

end

return AttackVfxSystem
