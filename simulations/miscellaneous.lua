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
    environment.create_roboport(surface, { 10, -6 })
    environment.create_container { type = "storage-chest", position = { -9, -5 }, items = { "landfill" } }

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

return miscellaneous
