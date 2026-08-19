--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const Dodge = require(ReplicatedStorage.Shared.Combat.Data.Dodge)
const VfxManifest = require(ReplicatedStorage.Shared.Combat.Data.VfxManifest)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const World = require(ReplicatedStorage.Shared.Combat.World)

const function DodgeSystem(tick: number, _delta: number)
    for entity, _dodgeIntent in World:query(Components.DodgeIntent):without(Components.Dead) do

        const activeAttack = World:has(entity, Components.ActiveAttack)
        const stunned = World:has(entity, Components.Stunned)
        const actionLock = World:has(entity, Components.ActionLock)
        const blockstun = World:has(entity, Components.Blockstun)

        if activeAttack or stunned or actionLock or blockstun then
            continue
        end

        const posture = World:get(entity, Components.Posture)
        if not posture then continue end
        if posture.Current < Dodge.PostureCost then continue end

        if World:has(entity, Components.Blocking) then
            World:remove(entity, Components.Blocking)
        end

        posture.Current -= Dodge.PostureCost
        posture.LastDamagedTick = tick

        World:set(entity, Components.ActionLock, {
            EndsAt = tick + Dodge.Startup + Dodge.Invulnerable + Dodge.Recovery,
            Mask = 2
        })

        World:set(entity, Components.Invulnerable, {
            StartsAt = tick + Dodge.Startup,
            EndsAt = tick + Dodge.Startup + Dodge.Invulnerable,
            Kind = "Dodge"
        } :: Components.Invulnerable)

        const characterRef = World:get(entity, Components.CharacterRef)
        if characterRef then
            Packets.Vfx.sendToAll({
                Character = characterRef.Model,
                Kind = VfxManifest.ReverseMap.Dodge,
                Duration = 0
            })
        end

        World:remove(entity, Components.DodgeIntent)
    end
end

return DodgeSystem