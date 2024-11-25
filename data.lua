local constants = require "constants"
local extended = {}

---@type boolean
---@diagnostic disable-next-line: assign-type-mismatch
local dev_mode = settings.startup["factoriopedia-extended-dev-mode"].value

---@generic T : data.PrototypeBase
---@param prototype T
---@param action fun(it: T)
local function modify(prototype, action)
    local copy = table.deepcopy(prototype)
    copy.name = constants.mod_name .. "-" .. prototype.name
    if not dev_mode then
        copy.hidden = true
    end
    copy.hidden_in_factoriopedia = true
    action(copy)
    table.insert(extended, copy)
    if prototype.type ~= "item" then
        modify(data.raw["item"][prototype.name], function (it)
            it.place_result = copy.name
        end)
    end
end

local bot_properties = {}
do
    local roboport_sound = data.raw["roboport"]["roboport"].working_sound
    local bot_sound = data.raw["construction-robot"]["construction-robot"].charging_sound
    local ch_sound = table.deepcopy(bot_sound)
    ch_sound.fade_ticks = 1000
    bot_properties.charging_sound = ch_sound
    bot_properties.speed = 0.3
    bot_properties.energy_per_move = "0kJ"
    bot_properties.energy_per_tick = "0kJ"
    bot_properties.max_to_charge = 0
    bot_properties.min_to_charge = 0
    bot_properties.speed_multiplier_when_out_of_energy = 1
    bot_properties.max_payload_size = 1
    bot_properties.working_sound = roboport_sound
end

modify(data.raw["roboport"]["roboport"], function(it)
    it.energy_source = { type = "void" }
end)

modify(data.raw["construction-robot"]["construction-robot"], function(it)
    for key, value in pairs(bot_properties) do it[key] = value end
end)

modify(data.raw["logistic-robot"]["logistic-robot"], function(it)
    for key, value in pairs(bot_properties) do it[key] = value end
end)

modify(data.raw["inserter"]["bulk-inserter"], function(it)
    it.extension_speed = 100
    it.rotation_speed = 100
    it.stack_size_bonus = 100
    it.energy_source = { type = "void" }
end)

modify(data.raw["item"]["solid-fuel"], function (it)
    it.burnt_result = nil
    it.fuel_value = "1QJ"
    it.stack_size = 10000
end)

data:extend(extended)
