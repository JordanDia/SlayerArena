const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Loader = require(ReplicatedStorage.Shared.Lib.Loader)

const serviceCount = Loader.Load(script, "Controller")
print(`Loaded {serviceCount} controllers`)