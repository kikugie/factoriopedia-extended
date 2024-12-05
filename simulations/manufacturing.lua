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

--- Creates a new patch for this drill to mine every 5 seconds
---@param prototype LuaEntityPrototype
---@return function?
local function setup_ore_sequence(prototype)
    local surface = game.surfaces[1]

    ---@param res string
    ---@return LuaEntity[]
    local function create_solid_ores(res)
        local ores = {} ---@type LuaEntity[]
        -- Approximate borders of the viewport
        local x_offset = math.ceil((prototype.tile_height + 3.5) * 4 / 3)
        local y_offset = math.ceil((prototype.tile_height + 3.5) / 2)
        for x, y in utilities.box { { -x_offset, -y_offset }, { x_offset, y_offset } } do
            --[[
            Vanilla ores have different sprites at 80, 150, 400, 1300, 2900, 5500, 9500 and 15000 thresholds.
            This roughly corresponds to 'y = 10.52378x^3.49348' formula, which is scaled down to 'y = 5x^3.5'.
            The amount of the ore in each square is determined by it's distance from the drill, but inverted
            to have maximum richness at the center and has a slight random offset.
            Created ores are stored in an array to be able to delete them easily later.

            Is this overengineered? Definitely yes.
            ]]
            local normalized_distance = math.min(math.sqrt(x * x + y * y) / x_offset, 1)
            if normalized_distance == 1 then goto continue end
            local ore_amount = (8 - normalized_distance * math.random(8, 10)) ^ 3.5 * 5
            if ore_amount ~= ore_amount or ore_amount < 1 then goto continue end
            local ore_entity = surface.create_entity { name = res, position = { x, y } }
            ore_entity.amount = ore_amount
            table.insert(ores, ore_entity)
            ::continue::
        end
        return ores
    end

    ---@param res string
    ---@return LuaEntity[]
    local function create_fluid_ore(res)
        return { surface.create_entity { name = res, position = { 0, 0 } } }
    end

    local patch_setters = {} ---@type {entity:string, setter:function}[]
    local patch_entities = {} ---@type LuaEntity[]
    local current_index = 0

    for _, entity in pairs(prototypes.entity) do
        local category = entity.resource_category
        if not category or not prototype.resource_categories[category] then goto continue end
        if category == "basic-solid" or category == "hard-solid" then
            table.insert(patch_setters, { entity = entity, setter = create_solid_ores })
        elseif category == "basic-fluid" then
            table.insert(patch_setters, { entity = entity, setter = create_fluid_ore })
        end
        ::continue::
    end

    if #patch_setters == 0 then return nil end
    return function()
        -- Fuck 1 indexing
        local entry = patch_setters[current_index + 1]
        current_index = (current_index + 1) % #patch_setters

        for _, ore in pairs(patch_entities) do
            if ore.valid then ore.destroy() end
        end
        patch_entities = entry.setter(entry.entity.name)
        return entry.entity
    end
end

function manufacturing.mining_drill(name)
    local surface = game.surfaces[1]
    local drill = prototypes.entity[name]
    if drill.tile_width % 2 == 1 then environment.center_viewport() end
    game.forces["enemy"].mining_drill_productivity_bonus = 10
    if drill.burner_prototype then
        environment.viewport_height(drill.tile_height + 3)
    else
        environment.viewport_height(drill.tile_height + 2)
    end
    environment.research_all()

    if drill.electric_energy_source_prototype then
        environment.setup_electricity(surface)
    end

    local update_ores = setup_ore_sequence(drill)
    if not update_ores then
        surface.create_entity { name = name, position = { 0, 0 } }
        return
    end

    local fluid_points = get_fluid_points(drill)
    local mining_fluid_points = {} ---@type FluidConnectionPoint[]
    local lowest_point = -10
    for _, value in pairs(fluid_points) do
        if value.fluidbox_type ~= "none" then goto continue end
        if value.position.y > lowest_point then mining_fluid_points = {} end
        table.insert(mining_fluid_points, value)
        ::continue::
    end

    do
        local output = vector.standardize(drill.vector_to_place_result)
        if output and output.x ~= 0 and output.y ~= 0 then
            local offset = math.ceil((drill.tile_height + 3.5) * 4 / 3)
            for x = -offset, offset do
                surface.create_entity { name = "transport-belt", position = { x, output.y }, direction = defines.direction.east }
            end
            environment.create_consumer { position = { offset + 1, output.y }, direction = defines.direction.east }
        end
    end

    do
        local output = table_extras.find_value(fluid_points, function (_, value)
            return value.fluidbox_type == "output"
        end)
        if output then environment.connect_pipe(output) end
    end

    local resettable_entities = {} ---@type LuaEntity[]
    local drill_entity = nil ---@type LuaEntity?
    local sequence = new_sequence()
    sequence:event(0, function()
        local current_resource = update_ores()
        if drill_entity and drill_entity.valid then drill_entity.destroy() end
        drill_entity = surface.create_entity { name = name, position = { 0, 0 } }

        for _, value in pairs(resettable_entities) do
            if value.valid then value.destroy() end
        end
        local required_fluid = current_resource.mineable_properties.required_fluid
        if required_fluid then
            for _, value in pairs(mining_fluid_points) do
                table_extras.insert_all(resettable_entities, environment.connect_pipe(value, required_fluid))
            end
        end
    end)
    sequence:finish(300)
end

return manufacturing
