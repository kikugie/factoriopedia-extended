local utilities = require "library.utilities"
local constants = require "constants"
local environment = {}

environment.default_force = "enemy"

--- Factoriopedia viewport is exactly 400x150 pixels, forming 8:3 ratio.
--- At camera scale 1.0 it's exactly 25 tiles wide.
--- This checks if the required height is more than the default and scales using these values.
---@param tiles uint
function environment.viewport_height(tiles)
    if tiles <= 4 or not game.simulation then return end
    local required_height = tiles + 0.5
    local normalized_height = 25 * 3 / 8
    local scale = normalized_height / required_height
    game.simulation.camera_zoom = scale
end

---@param tiles uint
function environment.viewport_width(tiles)
    if tiles <= 12 or not game.simulation then return end
    local required_width = tiles + 0.5
    local scale = 25 / required_width
    game.simulation.camera_zoom = scale
end

---@param y number?
function environment.center_viewport(y)
    if game.simulation then game.simulation.camera_position = { 0.5, y or 0 } end
end

function environment.research_all()
    for _, it in pairs(game.forces) do it.research_all_technologies() end
end

---@param surface LuaSurface
function environment.setup_electricity(surface)
    surface.create_global_electric_network()
    surface.create_entity { name = "electric-energy-interface", position = { 24, 14 } }
end

function environment.fuel(entity)
    local inv = entity.get_fuel_inventory()
    if inv then inv.insert(constants.mod_name .. "-solid-fuel") end
end

--- Fills the given area with the tile.
---@param surface LuaSurface
---@param tile string
---@param area BoundingBox
function environment.fill_tiles(surface, tile, area)
    local tiles = {}
    for x, y in utilities.box(area) do
        table.insert(tiles, { name = tile, position = { x, y } })
    end
    surface.set_tiles(tiles)
end

--- Creates a blueprint item from the string.
---@param data string
---@return LuaItemStack
function environment.blueprint(data)
    local inventory = game.create_inventory(1)
    inventory.insert { name = "blueprint" }
    local blueprint = inventory.find_item_stack("blueprint")
    ---@cast blueprint LuaItemStack
    blueprint.import_stack(data)
    return blueprint
end

--- Creates a roboport with no power requirements and 50 silent and energy-free construction and logistic bots.
---@param surface LuaSurface
---@param pos MapPosition
---@return LuaEntity?
function environment.roboport(surface, pos)
    local roboport = surface.create_entity {
        name = constants.mod_name .. "-roboport", position = pos
    }
    if not roboport then return nil end
    local inventory = roboport.get_inventory(defines.inventory.roboport_robot)
    if not inventory then return roboport end
    inventory.insert(constants.mod_name .. "-construction-robot")
    inventory.insert(constants.mod_name .. "-logistic-robot")
    return roboport
end

--- Creates a container of the given time and inserts items into it.
---@param surface LuaSurface
---@param type string
---@param position MapPosition
---@param ... ItemStackIdentification
---@return LuaEntity?
function environment.container(surface, type, position, ...)
    local chest = surface.create_entity { name = type, position = position }
    if not chest then return nil end
    local inventory = chest.get_inventory(defines.inventory.chest)
    if not inventory then return chest end
    local args = { ... }
    for _, value in pairs(args) do
        inventory.insert(value)
    end
    return chest
end

--- Directly pastes the given blueprint string on the surface.
---@param surface LuaSurface
---@param position MapPosition
---@param data string
function environment.paste(surface, position, data)
    ---@diagnostic disable-next-line: undefined-field
    surface.create_entities_from_blueprint_string {
        position = position,
        string = data,
        force = "enemy"
    }
end

---@param surface LuaSurface
---@param pos1 MapPosition Input belt location
---@param pos2 MapPosition Output belt location
---@param direction defines.direction Direction of the belt flow
function environment.create_linked_belts(surface, pos1, pos2, direction)
    local input_belt = surface.create_entity {
        name = constants.mod_name .. "-linked-belt", position = pos1, direction = direction
    }
    local output_belt = surface.create_entity {
        name = constants.mod_name .. "-linked-belt", position = pos2, direction = (direction + 8) % 16
    }
    output_belt.linked_belt_type = "output"
    output_belt.connect_linked_belts(input_belt)
end

return environment
