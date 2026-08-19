--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const jecs = require(ReplicatedStorage.Packages.Jecs)

export type World = jecs.World
export type Entity<T = nil> = jecs.Entity<T>

const world = jecs.world()

return world