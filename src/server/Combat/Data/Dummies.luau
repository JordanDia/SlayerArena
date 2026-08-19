--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")
const Components = require(ReplicatedStorage.Shared.Combat.Components)
const CombatantFactory = require(ServerScriptService.Server.Combat.CombatantFactory)

export type DummyKind = {
    read Stats: CombatantFactory.StatOverrides?,
    read StartsBlocking: boolean?,
    read Behavior: { Policy: Components.DummyPolicy, Interval: number }?
}

const Dummies: { [string]: DummyKind } = {

    Dummy = {  
        Stats = {
            Health = 100,
        },
        StartsBlocking = false,
    },

    Swinging = {
        Stats = {
            Health = 100000
        },

        Behavior = {
            Policy = "Swinging",
            Interval = 0
        },
    },

    Blocking = {
        Stats = {
            Health = 100000,
            Posture = 100000,
        },

        StartsBlocking = true
    },
    
    Punisher = {
        Stats = {
            Health = 100000,
            Posture = 100000,
        },

        Behavior = {
            Policy = "Punisher",
            Interval = 0,
        },

        StartsBlocking = true
    },
    

}

return table.freeze(Dummies)
