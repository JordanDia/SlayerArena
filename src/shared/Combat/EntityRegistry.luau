--!strict
const World = require("./World")

const EntityRegistry = {}

const entityByModel: { [Model]: World.Entity } = {}

function EntityRegistry.Register(model: Model, entity: World.Entity)
    if entityByModel[model] then
        error(`{ model.Name } model already has an entity!`)
    end

    entityByModel[model] = entity
end

function EntityRegistry.Unregister(model: Model)
    entityByModel[model] = nil
end

function EntityRegistry.Get(model: Model): World.Entity?
    return entityByModel[model]
end

return EntityRegistry