--!strict

const Pipeline = {}
Pipeline.__index = Pipeline

export type PipelineFields = {
    read _Systems: { SystemEntry },
    _Locked: boolean,
    _Names: { [string]: boolean }
}

export type System = (tick: number, delta: number) -> ()

export type SystemEntry = {
    Name: string,
    Fn: System
}

function Pipeline.new() : Pipeline
    local self: PipelineFields = {
        _Systems = {},
        _Locked = false,
        _Names = {},
    }

    setmetatable(self, Pipeline)
    return self
end

function Pipeline.Add(self: Pipeline, name: string, system: System): Pipeline
    if self._Locked then
        error(`Cannot add { name } - pipeline is locked`, 2)
    end

    if self._Names[name] then
        error(`{ name } is already taken - cannot add to pipeline. Choose a different name`, 2)
    end

    const entry: SystemEntry = {
        Name = name,
        Fn = system,
    }

    table.insert(self._Systems, entry)
    self._Names[name] = true

    return self
end

function Pipeline.Lock(self: Pipeline)
    self._Locked = true
end

function Pipeline.Run(self: Pipeline, tick: number, delta: number)
    for _, entry in self._Systems do
        debug.profilebegin(entry.Name)
        entry.Fn(tick, delta)
        debug.profileend()
    end
end

function Pipeline.GetRunner(self: Pipeline): System
    return function (tick: number, delta: number)
        self:Run(tick, delta)
    end
end

export type Pipeline = typeof(setmetatable({} :: PipelineFields, {} :: typeof(Pipeline)))

return Pipeline