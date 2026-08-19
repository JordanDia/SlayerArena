const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Loader = require(ReplicatedStorage.Shared.Lib.Loader)

const serviceCount = Loader.Load(script, "Service")
print(`Loaded {serviceCount} services`)