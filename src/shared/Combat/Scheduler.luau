--!strict

const RunService = game:GetService("RunService")

const Scheduler = {}

const TICK_RATE = 60
const TICK_DELTA = 1 / TICK_RATE
const MAX_CATCHUP_TICKS = 5

local currentTick = 0
local accumulator = 0
local connection: RBXScriptConnection? = nil

export type StepCallback = (tick: number, delta: number) -> ()

function Scheduler.GetTick(): number
	return currentTick
end

function Scheduler.SecondsToTicks(seconds: number): number
	return math.ceil(seconds * TICK_RATE)
end

function Scheduler.TicksToSeconds(ticks: number): number
	return ticks / TICK_RATE
end

function Scheduler.Start(step: StepCallback)
	if connection then
		error("Scheduler is already running", 0)
	end

	connection = RunService.PostSimulation:Connect(function(deltaTime: number)
		accumulator += deltaTime
		accumulator = math.min(accumulator, TICK_DELTA * MAX_CATCHUP_TICKS)
		while accumulator >= TICK_DELTA do
			accumulator -= TICK_DELTA
			currentTick += 1
			step(currentTick, TICK_DELTA)
		end
	end)
end

function Scheduler.Stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end

	accumulator = 0
end

return Scheduler
