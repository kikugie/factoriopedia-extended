---@diagnostic disable: need-check-nil
require "library.story"
local environment = require "library.environment"
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
    local input_belt = surface.create_entity {
        name = "linked-belt", position = { 9, belt_start.y }, direction = defines.direction.east
    }
    local output_belt = surface.create_entity {
        name = "linked-belt", position = { -9, belt_end.y }, direction = defines.direction.west
    }
    output_belt.linked_belt_type = "output"
    output_belt.connect_linked_belts(input_belt)
end

return belt_logistics