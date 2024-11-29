local constants = require "constants"
local fastest_speed = 0
for _, prototype in pairs(data.raw["underground-belt"]) do
    if prototype.speed > fastest_speed then
        fastest_speed = prototype.speed
    end
end

data.raw["linked-belt"][constants.mod_name .. "-linked-belt"].speed = fastest_speed
data.raw["loader-1x1"][constants.mod_name .. "-loader-1x1"].speed = fastest_speed