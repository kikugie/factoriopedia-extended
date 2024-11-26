local constants = require "constants"

local extended = {}

---@param prototype data.PrototypeBase
---@param name string
---@param prepare uint?
local function apply_simulation(prototype, name, prepare)
    if prototype.hidden or prototype.hidden_in_factoriopedia then return end
    prototype.factoriopedia_simulation = {
        mods = { constants.mod_name },
        init = [[remote.call("]] .. constants.mod_name .. [[", "]] .. name .. [[")]],
        init_update_count = prepare or 0
    }
    table.insert(extended, prototype)
end

local function apply_to_group(table, name, prepare)
    for _, entity in pairs(table) do
        apply_simulation(entity, name .. "\", \"" .. entity.name, prepare)
    end
end

apply_simulation(data.raw["tile"]["landfill"], "landfill")
apply_simulation(data.raw["logistic-container"]["storage-chest"], "storage_chest")
apply_simulation(data.raw["logistic-container"]["requester-chest"], "requester_chest")
apply_simulation(data.raw["logistic-container"]["active-provider-chest"], "active_provider_chest", 30)
apply_simulation(data.raw["logistic-container"]["passive-provider-chest"], "passive_provider_chest")
apply_simulation(data.raw["logistic-container"]["buffer-chest"], "buffer_chest")

apply_to_group(data.raw["inserter"], "inserter", 420)
apply_to_group(data.raw["roboport"], "roboport")
apply_to_group(data.raw["mining-drill"], "mining_drill")

if #extended > 0 then
    data:extend(extended)
end
