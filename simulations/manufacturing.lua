require "library.story"
local environment   = require "library.environment"
local blueprints    = require "blueprints"
local constants     = require "constants"
local utilities     = require "library.utilities"
local vector        = require "library.vector"
local table_extras  = require "library.table_extras"
local manufacturing = {}

---@param prototype LuaEntityPrototype
---@return FluidConnectionPoint[]
local function get_fluid_points(prototype)
    local fluid_parameters = {}
    for _, fluidbox in pairs(prototype.fluidbox_prototypes) do
        for _, connection in pairs(fluidbox.pipe_connections) do
            table.insert(fluid_parameters, {
                fluidbox_type = fluidbox.production_type,
                flow_direction = connection.flow_direction,
                connection_type = connection.connection_type,
                position = vector.standardize(connection.positions[1]),
                temperature = fluidbox.minimum_temperature,
                underground_distance = connection.max_underground_distance,
                filter = fluidbox.filter,
                direction = connection.direction
            })
        end
    end
    return fluid_parameters
end

---@param prototype LuaEntityPrototype
local function solid_drill(prototype)
    local surface = game.surfaces[1]
    local height_mod = 2
    if prototype.burner_prototype then height_mod = 3.5 end
    local viewport = environment.configure_viewport {
        center = prototype.tile_width % 2 == 1,
        height = prototype.tile_height + height_mod
    }
    game.forces["enemy"].mining_drill_productivity_bonus = 10

    -- Find resources this drill can mine. If there are none for some reason, place the entity and leave
    local accepted_categories = prototype.resource_categories ---@type {[string]: boolean}
    local accepted_resources = table_extras.filter_values(prototypes.entity, function(_, entity)
        return entity.resource_category and accepted_categories[entity.resource_category]
    end)
    if #accepted_resources == 0 then
        surface.create_entity { name = prototype, position = { 0, 0 } }
        return
    end

    -- Place a row of belts at the output position
    local output = vector.standardize(prototype.vector_to_place_result)
    for x = viewport.tile_box.left_top.x, viewport.tile_box.right_bottom.x do
        surface.create_entity { name = "transport-belt", position = { x, output.y }, direction = defines.direction.east }
    end
    environment.create_consumer { position = { viewport.tile_box.right_bottom.x + 1, output.y }, direction = defines.direction.east }

    -- Find all fluid connections and filter out the bottommost ones used to mine a resource
    local fluid_points = get_fluid_points(prototype)
    local mining_fluid_points = {} ---@type FluidConnectionPoint[]
    local lowest_point = viewport.tile_box.left_top.y
    for _, value in pairs(fluid_points) do
        if value.fluidbox_type ~= "none" then goto continue end
        if value.position.y > lowest_point then mining_fluid_points = {} end
        table.insert(mining_fluid_points, value)
        ::continue::
    end

    if prototype.electric_energy_source_prototype then
        environment.setup_electricity(surface)
    elseif prototype.burner_prototype then
        -- Run a belt below the drill and supply it with the cheap coal
        local belt_y = math.ceil(prototype.tile_height / 2) + 1
        for x = viewport.tile_box.left_top.x, viewport.tile_box.right_bottom.x do
            surface.create_entity { name = "transport-belt", position = { x, belt_y }, direction = defines.direction.west }
        end
        environment.create_supplier {
            position = { viewport.tile_box.right_bottom.x + 1, belt_y },
            direction = defines.direction.west,
            left_filter = constants.mod_name .. "-coal"
        }
        -- Find inserter position that doesn't intersect with pipe connection points
        local inserter_x = -math.floor(prototype.tile_width / 2)
        for x = inserter_x, inserter_x + prototype.tile_width do
            local fluid_point = table_extras.find_value(fluid_points, function(_, value)
                if value.connection_type ~= "normal" then return false end
                local pipe_pos = vector.offset(value.position, value.direction)
                return pipe_pos.x == x and pipe_pos.y == belt_y - 1
            end)
            if not fluid_point then
                surface.create_entity { name = "burner-inserter", position = { x, belt_y - 1 }, direction = defines.direction.south }
                break
            end
        end
    end

    --- Create ore patch around the drill
    ---@param res string
    ---@return LuaEntity[]
    local function create_solid_ores(res)
        local proxy = environment.surface()
        for x, y in utilities.box(viewport.tile_box) do
            --[[
            Vanilla ores have different sprites at 80, 150, 400, 1300, 2900, 5500, 9500 and 15000 thresholds.
            This roughly corresponds to 'y = 10.52378x^3.49348' formula, which is scaled down to 'y = 5x^3.5'.
            The amount of the ore in each square is determined by it's distance from the drill, but inverted
            to have maximum richness at the center and has a slight random offset.
            Created ores are stored in an array to be able to delete them easily later.

            Is this overengineered? Definitely yes.
            ]]
            local normalized_distance = math.min(math.sqrt(x * x + y * y) / viewport.width, 1)
            if normalized_distance == 1 then goto continue end
            local ore_amount = (8 - normalized_distance * math.random(8, 10)) ^ 3.5 * 5
            if ore_amount ~= ore_amount or ore_amount < 1 then goto continue end
            local ore_entity = proxy:create_entity { name = res, position = { x, y } }
            ore_entity.amount = ore_amount
            ::continue::
        end
        return proxy.entities
    end

    local function create_pipe_connections(fluid)
        local pipes = {}
        for _, p in pairs(mining_fluid_points) do
            table_extras.insert_all(pipes, environment.connect_pipe(p, fluid))
        end
        return pipes
    end

    local cycle = 0
    local drill = nil ---@type LuaEntity?
    local resettable_entities = {} ---@type LuaEntity[]
    local sequence = new_sequence()
    -- Reset ore patch, pipes and the drill itself every cycle
    sequence:event(0, function()
        for _, it in pairs(resettable_entities) do
            if it.valid then it.destroy() end
        end
        resettable_entities = {}

        local resource = accepted_resources[cycle + 1]
        cycle = (cycle + 1) % #accepted_resources
        table_extras.insert_all(resettable_entities, create_solid_ores(resource.name))

        local fluid = resource.mineable_properties.required_fluid
        if fluid then table_extras.insert_all(resettable_entities, create_pipe_connections(fluid)) end

        if drill and drill.valid then drill.destroy() end
        drill = surface.create_entity { name = prototype.name, position = { 0, 0 } }
    end)
    sequence:finish(300, 600)
end

local function fluid_drill(prototype)

end

function manufacturing.mining_drill(name)
    local drill = prototypes.entity[name]
    local resources = drill.resource_categories
    log(serpent.line(resources))
    if not resources then
        game.surfaces[1].create_entity { name = name, position = { 0, 0 } }
    elseif resources["basic-solid"] then
        solid_drill(drill)
    --elseif resources["basic-fluid"] then
    --    fluid_drill(drill)
    else
        game.surfaces[1].create_entity { name = name, position = { 0, 0 } }
    end
end

return manufacturing
