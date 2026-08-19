--!strict

const Loader = {
}

export type LoadedModule = {
    Init: ((self: LoadedModule) -> ())?,
    Start: ((self: LoadedModule) -> ())?,
}

function Loader.Load(container: Instance, suffix: string)

    const modules: { LoadedModule } = {}

    for _, descendant in container:GetDescendants() do
        if descendant:IsA("ModuleScript") and descendant.Name:sub(-#suffix) == suffix then
            const function errorFunction(err: string): string
                return debug.traceback(err, 2)
            end
            const success, result = xpcall(require, errorFunction, descendant)
            
            if success then
                if typeof(result) ~= "table" then
                    error(`Module did not return a table:\n{descendant:GetFullName()}`, 0)
                end
                table.insert(modules, result)
            else
                error(`Failed to load module: {descendant:GetFullName()} ,\n{result}`, 0)
            end
        end
    end

    for _, module in modules do
        if module.Init then
            module:Init()
        end
    end

    for _, module in modules do
        task.spawn(function()
            if module.Start then
                module:Start()
            end
        end)
    end

    return #modules
end

return Loader