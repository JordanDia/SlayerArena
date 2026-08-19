const Components = require("../Components")
const World = require("../World")

const function StaminaRegenSystem(tick: number, _delta: number)
    for _entity, stamina in World:query(Components.Stamina):without(Components.Dead) do
        stamina.Current += stamina.RegenPerTick
        stamina.Current = math.min(stamina.Current, stamina.Max)
    end
end

return StaminaRegenSystem