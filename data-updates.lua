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

apply_simulation(data.raw["tile"]["landfill"], "landfill")
apply_simulation(data.raw["logistic-container"]["storage-chest"], "storage_chest")
apply_simulation(data.raw["logistic-container"]["requester-chest"], "requester_chest")
apply_simulation(data.raw["logistic-container"]["active-provider-chest"], "active_provider_chest")
apply_simulation(data.raw["logistic-container"]["passive-provider-chest"], "passive_provider_chest")
apply_simulation(data.raw["logistic-container"]["buffer-chest"], "buffer_chest")

for _, entity in pairs(data.raw["inserter"]) do
    apply_simulation(entity, "inserter\", \"" .. entity.name, 420)
end

for _, entity in pairs(data.raw["mining-drill"]) do
    apply_simulation(entity, "mining_drill\", \"" .. entity.name)
end

if #extended > 0 then
    data:extend(extended)
end
