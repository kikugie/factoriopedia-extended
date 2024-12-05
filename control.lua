local functions = {}
local function scoop(path)
    local table = require(path)
    for key, value in pairs(table) do
        if type(value) == "function" then functions[key] = value end
    end
end

scoop "simulations.bot_logistics"
scoop "simulations.belt_logistics"
scoop "simulations.manufacturing"
scoop "simulations.miscellaneous"

remote.add_interface(script.mod_name, functions)
