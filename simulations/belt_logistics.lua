---@diagnostic disable: need-check-nil
require "library.story"
local environment    = require "library.environment"
local blueprints     = require "blueprints"
local constants      = require "constants"
local belt_logistics = {}

function belt_logistics.inserter(name)
    local surface = game.surfaces[1]
    environment.research_all()
    environment.setup_electricity(surface)
    game.simulation.camera_position = { 0.5, 0 }
    game.forces["enemy"].mining_drill_productivity_bonus = 10

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
    local chest = environment.container(surface, "steel-chest", { 0, 0 }, { name = "iron-gear-wheel", count = 1000 })
    local drop_inserter = surface.create_entity {
        name = name, position = { -pickup.x, -pickup.y }, direction = defines.direction.west
    }
    local pickup_inserter = surface.create_entity {
        name = name, position = { -drop.x, -drop.y }, direction = defines.direction.west
    }
    environment.fuel(drop_inserter)
    environment.fuel(pickup_inserter)

    -- Create a belt running across the viewport and loop it with linked belt
    local belt_start = { x = -pickup.x + drop.x, y = -pickup.y + drop.y }
    local belt_end = { x = -drop.x + pickup.x, y = -drop.y + pickup.y }
    for x = belt_start.x, 8 do
        surface.create_entity { name = "transport-belt", direction = defines.direction.east, position = { x, belt_start.y } }
    end
    for x = -8, belt_end.x do
        surface.create_entity { name = "transport-belt", direction = defines.direction.east, position = { x, belt_end.y } }
    end
    environment.create_linked_belts(surface, { 9, belt_start.y }, { -9, belt_end.y }, defines.direction.east)
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
    environment.create_linked_belts(surface, { 9, 0 }, { -9, 0 }, defines.direction.east)
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
    environment.create_linked_belts(surface, { border + 1, 0 }, { -border - 1, 0 }, defines.direction.east)
end

function belt_logistics.splitter(name, related_belt)
    local surface = game.surfaces[1]
    environment.center_viewport()

    local splitter = surface.create_entity { name = name, position = { 0, -1 }, direction = defines.direction.east }
    -- TODO: Rest of the simulation
end

return belt_logistics
