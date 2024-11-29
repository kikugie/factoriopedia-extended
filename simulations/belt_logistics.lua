---@diagnostic disable: need-check-nil
require "library.story"
local environment    = require "library.environment"
local blueprints     = require "blueprints"
local constants      = require "constants"
local belt_logistics = {}

function belt_logistics.inserter(name)
    local surface = game.surfaces[1]
    environment.research_all()
    environment.center_viewport()

    -- Determine the pickup and drop positions of the inserter
    local inserter = prototypes.entity[name]
    local pickup = {
        x = math.floor(inserter.inserter_pickup_position[2]),
        y = -math.floor(inserter.inserter_pickup_position[1])
    }
    local drop = {
        x = math.floor(inserter.inserter_drop_position[2]),
        y = -math.floor(inserter.inserter_drop_position[1])
    }

    -- Actors of this scene
    environment.create_container {
        surface = surface,
        type = "steel-chest",
        position = { 0, 0 },
        items = { { name = "iron-gear-wheel", count = 1000 } }
    }
    surface.create_entity { name = name, position = { -pickup.x, -pickup.y }, direction = defines.direction.west }
    surface.create_entity { name = name, position = { -drop.x, -drop.y }, direction = defines.direction.west }

    -- Create a belt running across the viewport and loop it with linked belt
    local belt_start = { x = -pickup.x + drop.x, y = -pickup.y + drop.y }
    local belt_end = { x = -drop.x + pickup.x, y = -drop.y + pickup.y }
    local total_width = -belt_end.x + belt_start.x + 1
    environment.viewport_width(total_width)

    local west_border = math.min(belt_end.x - 1, -6)
    local east_border = math.max(belt_start.x + 1, 6)

    for x = west_border, belt_end.x do
        surface.create_entity { name = "transport-belt", direction = defines.direction.east, position = { x, belt_end.y } }
    end
    for x = belt_start.x, east_border do
        surface.create_entity { name = "transport-belt", direction = defines.direction.east, position = { x, belt_start.y } }
    end
    environment.create_linked_belts {
        surface = surface,
        direction = defines.direction.east,
        input = { east_border + 1, belt_start.y },
        output = { west_border - 1, belt_end.y }
    }

    if inserter.electric_energy_source_prototype then environment.setup_electricity(surface) end
    if not inserter.burner_prototype then return end
    -- Fuck it, can't deal with the inserter math anymore
    surface.create_entity { name = "burner-inserter", position = { -pickup.x, -pickup.y - 1 }, direction = defines.direction.north }
    surface.create_entity { name = "burner-inserter", position = { -drop.x, -drop.y - 1 }, direction = defines.direction.north }
    for x = west_border, east_border do
        surface.create_entity { name = "transport-belt", direction = defines.direction.east, position = { x, -pickup.y - 2 } }
    end
    environment.create_supplier {
        surface = surface,
        position = { west_border - 1, -pickup.y - 2 },
        direction = defines.direction.east,
        right_filter = constants.mod_name .. "-coal"
    }
end

function belt_logistics.belt(name)
    local surface = game.surfaces[1]
    environment.center_viewport()

    for x = -8, 8 do
        surface.create_entity { name = name, position = { x, 0 }, direction = defines.direction.east }
    end

    surface.create_entity { name = constants.mod_name .. "-bulk-inserter", position = { -8, -1 }, direction = defines.direction.north }
    surface.create_entity { name = constants.mod_name .. "-bulk-inserter", position = { -8, 1 }, direction = defines.direction.south }
    surface.create_entity { name = "wooden-chest", position = { -8, -2 } }.get_inventory(defines.inventory.chest)
        .insert { name = "iron-gear-wheel", count = 70 }
    surface.create_entity { name = "wooden-chest", position = { -8, 2 } }.get_inventory(defines.inventory.chest)
        .insert { name = "iron-gear-wheel", count = 70 }
    environment.create_linked_belts { surface = surface, direction = defines.direction.east, input = { 9, 0 }, output = { -9, 0 } }
end

function belt_logistics.underground_belt(name, related_belt)
    local surface = game.surfaces[1]

    local distance = prototypes.entity[name].max_underground_distance
    if distance % 2 == 0 then environment.center_viewport() end -- Distance doesn't include the entrance
    environment.viewport_width(distance + 3)

    local entrance = -distance / 2
    local exit = distance / 2
    local border = math.floor(math.max(12, distance + 3) / 2 + 3)

    surface.create_entity { name = name, position = { entrance, 0 }, direction = defines.direction.east }
    surface.create_entity { name = name, position = { exit, 0 }, direction = defines.direction.west }

    for x = -border, entrance - 1 do
        surface.create_entity { name = related_belt, position = { x, 0 }, direction = defines.direction.east }
    end
    for x = exit, border + 1 do
        surface.create_entity { name = related_belt, position = { x, 0 }, direction = defines.direction.east }
    end
    surface.create_entity { name = constants.mod_name .. "-bulk-inserter", position = { -border, -1 }, direction = defines.direction.north }
    surface.create_entity { name = constants.mod_name .. "-bulk-inserter", position = { -border, 1 }, direction = defines.direction.south }
    local gear_count = border * 8 + 4
    surface.create_entity { name = "wooden-chest", position = { -border, -2 } }.get_inventory(defines.inventory.chest)
        .insert { name = "iron-gear-wheel", count = gear_count }
    surface.create_entity { name = "wooden-chest", position = { -border, 2 } }.get_inventory(defines.inventory.chest)
        .insert { name = "iron-gear-wheel", count = gear_count }
    environment.create_linked_belts { surface = surface, direction = defines.direction.east, input = { border + 1, 0 }, output = { -border - 1, 0 } }
end

function belt_logistics.splitter(name, related_belt)
    local surface = game.surfaces[1]
    environment.center_viewport()
    game.simulation.camera_alt_info = true

    local underground_belt = prototypes.entity[related_belt].related_underground_belt.name
    local splitter = surface.create_entity { name = name, position = { 0, 0 }, direction = defines.direction.east }
    for x = -8, 8 do
        surface.create_entity { name = related_belt, position = { x, -1 }, direction = defines.direction.east }
        surface.create_entity { name = related_belt, position = { x, 0 }, direction = defines.direction.east }
    end
    surface.create_entity { name = related_belt, position = { -9, -1 }, direction = defines.direction.east }
    surface.create_entity { name = related_belt, position = { -10, -1 }, direction = defines.direction.east }
    surface.create_entity { name = underground_belt, position = { -11, 0 }, direction = defines.direction.east }
    surface.create_entity { name = underground_belt, position = { -9, 0 }, direction = defines.direction.west }
    environment.paste(surface, { -10, 0 }, blueprints.splitter_env)
    environment.paste(surface, { 11, 0 }, blueprints.splitter_env2)

    local sequence = new_sequence()
    sequence:event(0, function()
        splitter.splitter_filter = nil
        splitter.splitter_output_priority = "none"
    end)
    sequence:event(180, function()
        splitter.splitter_filter = "iron-gear-wheel"
        splitter.splitter_output_priority = "left"
    end)
    sequence:event(360, function()
        splitter.splitter_filter = "deconstruction-planner"
        splitter.splitter_output_priority = "right"
    end)
    sequence:finish(540, 540)
end

return belt_logistics
