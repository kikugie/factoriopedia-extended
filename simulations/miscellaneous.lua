---@diagnostic disable: need-check-nil
require "library.story"
local environment   = require "library.environment"
local blueprints    = require "blueprints"
local constants     = require "constants"
local utilities     = require "library.utilities"
local miscellaneous = {}

function miscellaneous.landfill()
    local surface = game.surfaces[1]
    environment.fill_tiles(surface, "water", { { -7, -3 }, { 8, 3 } })
    environment.roboport(surface, { 10, -6 })
    environment.container(surface, "storage-chest", { -9, -5 }, "landfill")

    local player = game.simulation.create_test_player {
        name = "Player"
    }

    local blueprint = environment.blueprint(blueprints.landfill)

    local sequence = new_sequence()
    sequence:event(0, function()
        player.teleport { -9, 0 }
    end)
    sequence:event(30, function()
        blueprint.build_blueprint { surface = surface, position = { 0, 0 }, force = environment.default_force }
    end)
    sequence:event(120, function()
        player.walking_state = { walking = true, direction = defines.direction.east }
    end)
    sequence:event(270, function()
        surface.deconstruct_area { area = { { -7, -1 }, { 7, 1 } }, force = environment.default_force }
        player.walking_state = { walking = false, direction = defines.direction.east }
    end)
    sequence:finish(480)
end

function miscellaneous.mining_drill(name)
    local surface = game.surfaces[1]
    local drill = prototypes.entity[name]

    if drill.tile_width % 2 == 1 then environment.center_viewport() end
    environment.viewport_height(drill.tile_height + 2)
    environment.setup_electricity(surface)
    environment.research_all()

    -- List resources minable by this drill
    ---@type string[]
    local resources = utilities.collect(prototypes.entity, function(key, value)
        local resource = value.resource_category
        if not resource or not drill.resource_categories[resource] then
            return nil
        end
        return key
    end)

    -- Create output belt
    local belt_y = -math.floor(drill.tile_height / 2) - 1
    for x = -15, 15 do
        surface.create_entity { name = "transport-belt", direction = defines.direction.east, position = { x, belt_y } }
    end
    surface.create_entity {
        name = constants.mod_name .. "-bulk-inserter", direction = defines.direction.north, position = { 15, belt_y + 1 }
    }
    local chest = surface.create_entity { name = "infinity-chest", position = { 15, belt_y + 2 } }
    chest.remove_unfiltered_items = true

    ---@type LuaEntity
    local drill_entity
    -- TODO: Some modded miners require fluid input for all ores
    function update_drill(ore)
        if drill_entity and drill_entity.valid then drill_entity.destroy() end
        ---@diagnostic disable-next-line: cast-local-type
        drill_entity = surface.create_entity { name = name, position = { 0, 0 } }
        environment.fuel(drill_entity)

        for _, pipe in pairs(surface.find_entities_filtered {
            name = { "pipe", "infinity-pipe" },
            area = { { -25, -15 }, { 25, 15 } },
        }) do pipe.destroy() end

        local fluid = prototypes.entity[ore].mineable_properties.required_fluid
        if not fluid then return end

        for i = 1, #drill_entity.fluidbox do
            local max_y = -25
            local points = {}
            for _, value in pairs(drill_entity.fluidbox.get_pipe_connections(i)) do
                local target = value.target_position
                if target.y > max_y then
                    max_y = target.y
                    points = {}
                end
                table.insert(points, target)
            end

            for _, connection in pairs(points) do
                for y = connection.y, 10 do
                    surface.create_entity { name = "pipe", position = { connection.x, y } }
                end
                local source = surface.create_entity { name = "infinity-pipe", position = { connection.x, 10 } }
                source.set_infinity_pipe_filter {
                    name = fluid, percentage = 1.0
                }
            end
        end
    end

    -- Fill the viewport with a new ore every cycle
    local cycle = 1
    local patch = {}
    local sequence = new_sequence()
    sequence:event(0, function()
        local resource = resources[cycle]
        cycle = cycle + 1
        if cycle > #resources then cycle = 1 end

        for _, ore in pairs(patch) do ore.destroy() end
        for x, y in utilities.box { { -15, -7 }, { 15, 7 } } do
            local ore = surface.create_entity { name = resource, position = { x, y } }
            table.insert(patch, ore)
            ore.amount = math.random(5, 500)
        end
        update_drill(resource)
    end)

    sequence:finish(300)
end

return miscellaneous
