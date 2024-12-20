local constants = require "constants"
local extended = {}

---@type boolean
---@diagnostic disable-next-line: assign-type-mismatch
local dev_mode = settings.startup["factoriopedia-extended-dev-mode"].value

---@generic T : data.PrototypeBase
---@param prototype T
---@param action fun(it: T)?
local function modify(prototype, action)
    local copy = table.deepcopy(prototype)
    copy.name = constants.mod_name .. "-" .. prototype.name
    copy.hidden_in_factoriopedia = true
    copy.placeable_by = { item = copy.name, count = 1}
    copy.minable = { mining_time = 0.1, result = copy.name }
    if not dev_mode then copy.hidden = true end
    if action then action(copy) end
    table.insert(extended, copy)
    if copy.type == "item" then
        copy.subgroup = "other"
    else
        local item = data.raw["item"][prototype.name]
        if not item then
            item = {
                type = "item",
                icon = prototype.icon,
                name = prototype.name,
                stack_size = 50,
            }
        end

        modify(item, function(it)
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
    it.energy_source = { type = "void" }
end)

modify(data.raw["inserter"]["long-handed-inserter"], function(it)
    it.extension_speed = 100
    it.rotation_speed = 100
    it.energy_source = { type = "void" }
end)

modify(data.raw["linked-belt"]["linked-belt"])
modify(data.raw["loader-1x1"]["loader-1x1"], function(it)
    it.filter_count = 2
    it.per_lane_filters = true
    it.container_distance = 1
end)

modify(data.raw["item"]["solid-fuel"], function(it)
    it.fuel_value = "1QJ"
    it.stack_size = 10000
end)

modify(data.raw["item"]["coal"], function (it)
    it.fuel_value = "750kJ"
end)

data:extend(extended)
