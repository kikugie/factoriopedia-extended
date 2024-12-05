local utilities      = require "library.utilities"
local constants      = require "constants"
local vector         = require "library.vector"
local table_extras   = require "library.table_extras"
local environment    = {}

---@class SurfaceProxy
---@field surface LuaSurface
---@field entities LuaEntity[]
local SurfaceProxy   = {}
SurfaceProxy.__index = SurfaceProxy

---@param name any
---@param position MapPosition
local function create_error(name, position)
    error("Failed to create " .. serpent.line(name) .. " at (" .. position[1] .. ", " .. position[2] .. ")")
end

---@param param LuaSurface.create_entity_param
---@return LuaEntity?
function SurfaceProxy:try_create_entity(param)
    local entity = self.surface.create_entity(param)
    if entity then table.insert(self.entities, entity) end
    return entity
end

---@param param LuaSurface.create_entity_param
---@return LuaEntity
function SurfaceProxy:create_entity(param)
    local entity = self:try_create_entity(param)
    if not entity then create_error(param.name, param.position) end
    return entity
end

---@param override LuaSurface?
---@return SurfaceProxy
function environment.surface(override)
    local delegate = override or game.surfaces[1]
    local proxy = setmetatable({}, SurfaceProxy)
    proxy.surface = delegate
    proxy.entities = {}
    return proxy
end

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
function environment.create_roboport(surface, pos)
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

---@class CreateContainerParams
---@field surface LuaSurface?
---@field type EntityID
---@field position MapPosition
---@field items ItemStackIdentification[]
local CreateContainerParams = {}
---@param param CreateContainerParams
---@return LuaEntity
function environment.create_container(param)
    local surface = param.surface or game.surfaces[1]
    local chest = surface.create_entity { name = param.type, position = param.position }
    if not chest then create_error(param.type, param.position) end
    local inventory = chest.get_inventory(defines.inventory.chest)
    if not inventory then error("Failed to get chest inventory") end
    for _, value in pairs(param.items) do
        inventory.insert(value)
    end
    return chest
end

---@class CreateLinkedBeltsParams
---@field surface LuaSurface?
---@field input MapPosition
---@field output MapPosition
---@field direction defines.direction Direction of the belt flow
local CreateLinkedBeltsParams = {}
---@param param CreateLinkedBeltsParams
---@return LuaEntity[]
function environment.create_linked_belts(param)
    local proxy = environment.surface(param.surface)
    local input_belt = proxy:create_entity { name = constants.mod_name .. "-linked-belt", position = param.input, direction = param.direction }
    local output_belt = proxy:create_entity { name = constants.mod_name .. "-linked-belt", position = param.output, direction = (param.direction + 8) % 16 }
    output_belt.linked_belt_type = "output"
    output_belt.connect_linked_belts(input_belt)
    return proxy.entities
end

---@class CreateSupplierParams
---@field surface LuaSurface?
---@field position MapPosition
---@field direction defines.direction Direction of the output belt flow
---@field left_filter string|"none"|nil Name of the item, "none" to block the lane, nil to duplicate the other
---@field right_filter string|"none"|nil Name of the item, "none" to block the lane, nil to duplicate the other
local CreateSupplierParams = {}
---@param param CreateSupplierParams
---@return LuaEntity[]
function environment.create_supplier(param)
    local proxy = environment.surface(param.surface)
    local loader = proxy:create_entity { name = constants.mod_name .. "-loader-1x1", position = param.position, direction = param.direction }
    local chest = proxy:create_entity { name = "infinity-chest", position = vector.offset(param.position, param.direction, -1) }

    ---@type string|nil
    local left_filter = "deconstruction-planner"
    if not param.left_filter then
        left_filter = param.right_filter
    elseif param.left_filter ~= "none" then
        left_filter = param.left_filter
    end

    ---@type string|nil
    local right_filter = "deconstruction-planner"
    if not param.right_filter then
        right_filter = param.left_filter
    elseif param.right_filter ~= "none" then
        right_filter = param.right_filter
    end

    loader.set_filter(1, { index = 1, name = left_filter })
    loader.set_filter(2, { index = 2, name = right_filter })
    if left_filter ~= "deconstruction-planner" then
        chest.set_infinity_container_filter(1, { index = 1, name = left_filter, count = 10 })
    end
    if right_filter ~= "deconstruction-planner" then
        chest.set_infinity_container_filter(1, { index = 1, name = right_filter, count = 10 })
    end
    return proxy.entities
end

---@class CreateConsumerParams
---@field surface LuaSurface?
---@field position MapPosition
---@field direction defines.direction Direction of the input belt flow
local CreateConsumerParams = {}
---@param param CreateConsumerParams
---@return LuaEntity[]
function environment.create_consumer(param)
    local proxy = environment.surface(param.surface)
    local loader = proxy:create_entity { name = constants.mod_name .. "-loader-1x1", position = param.position, direction = (param.direction + 8) % 16 }
    local chest = proxy:create_entity { name = "infinity-chest", position = vector.offset(param.position, param.direction) }
    loader.loader_type = "input"
    chest.remove_unfiltered_items = true
    return proxy.entities
end

---@class FluidConnectionPoint
---@field surface LuaSurface?
---@field position MapPosition
---@field direction defines.direction
---@field fluidbox_type "input"|"output"|"input-output"|"none"
---@field flow_direction "input"|"output"|"input-output"
---@field connection_type "normal"|"underground"|"linked"
---@field temperature number?
---@field underground_distance uint?
---@field filter string?
local FluidConnectionPoint = {}
---@param param FluidConnectionPoint
---@param fluid string?
---@return LuaEntity[]
function environment.connect_pipe(param, fluid)
    local proxy = environment.surface(param.surface)
    local running_offset = 0
    if param.connection_type == "normal" then
        proxy:create_entity { name = "pipe-to-ground", position = vector.offset(param.position, param.direction), direction = (param.direction + 8) % 16 }
        running_offset = 1
    end
    running_offset = running_offset + (param.underground_distance
        or prototypes.entity["pipe-to-ground"].max_underground_distance)
    proxy:create_entity { name = "pipe-to-ground", position = vector.offset(param.position, param.direction, running_offset), direction = param.direction }
    local infinity_pipe = proxy:create_entity { name = "infinity-pipe", position = vector.offset(param.position, param.direction, running_offset + 1) }
    local filter = fluid or param.filter
    if filter then
        infinity_pipe.set_infinity_pipe_filter {
            name = filter,
            temperature = param.temperature
        }
    end
    return proxy.entities
end

return environment
