---@diagnostic disable: need-check-nil
require "library.story"
local environment   = require "library.environment"
local blueprints    = require "blueprints"
local bot_logistics = {}

function bot_logistics.storage_chest()
    local surface = game.surfaces[1]
    environment.center_viewport()
    environment.create_roboport(surface, { 0, -5 })
    environment.setup_electricity(surface)
    game.simulation.camera_alt_info = true

    environment.create_container {
        type = "storage-chest",
        position = { -2, 0 },
        items = { { name = "small-lamp", count = 1 } }
    }

    --  |    C   L    |  Chest and lamp setup
    local blueprint = environment.blueprint(blueprints.storage_chest)
    local sequence = new_sequence()
    sequence:event(30, function() -- Build green lamp from the chest
        blueprint.build_blueprint { position = { 2, 0 }, force = "enemy" }
    end)
    sequence:event(180, function() -- Remove the lamp and store the item
        surface.deconstruct_area { area = { { 2, 0 }, { 2, 0 } }, force = "enemy" }
    end)
    sequence:finish(360)
end

function bot_logistics.requester_chest()
    local surface = game.surfaces[1]
    game.simulation.camera_alt_info = true
    environment.center_viewport()
    environment.create_roboport(surface, { -1, -5 })

    --  |    R   C    |  Chest setup
    local requester = surface.create_entity { name = "requester-chest", position = { -2, 0 } }
    local storage = surface.create_entity { name = "storage-chest", position = { 2, 0 } }
    local section = requester.get_logistic_sections().add_section("")
    section.active = false
    section.set_slot(1, { value = "iron-gear-wheel", min = 10 })

    local sequence = new_sequence()
    sequence:event(0, function() -- Add gears to storage to be delivered to the requester
        storage.get_inventory(defines.inventory.chest)
            .insert { name = "iron-gear-wheel", count = 10 }
    end)
    sequence:event(30, function() -- Move gears to the requester
        section.active = true
    end)
    sequence:event(180, function() -- Disable the request and clear the inventory
        section.active = false
        requester.get_inventory(defines.inventory.chest)
            .clear()
    end)
    sequence:finish(240)
end

function bot_logistics.passive_provider_chest()
    local surface = game.surfaces[1]
    game.simulation.camera_alt_info = true
    environment.center_viewport()
    environment.create_roboport(surface, { -1, -5 })

    --  |    P   R    |  Chest setup
    local storage = environment.container(surface, "passive-provider-chest", { -2, 0 })
    local requester = environment.container(surface, "requester-chest", { 2, 0 })
    local section = requester.get_logistic_sections().add_section("")
    section.active = false
    section.set_slot(1, { value = "iron-gear-wheel", min = 10 })

    local sequence = new_sequence()
    sequence:event(0, function() -- Add gears to storage to be delivered to the requester
        storage.get_inventory(defines.inventory.chest)
            .insert { name = "iron-gear-wheel", count = 10 }
    end)
    sequence:event(30, function() -- Move gears to the requester
        section.active = true
    end)
    sequence:event(180, function() -- Disable the request and clear the inventory
        section.active = false
        requester.get_inventory(defines.inventory.chest)
            .clear()
    end)
    sequence:finish(240)
end

function bot_logistics.active_provider_chest()
    local surface = game.surfaces[1]
    game.simulation.camera_alt_info = true
    environment.center_viewport()
    environment.create_roboport(surface, { -1, -5 })
    environment.setup_electricity(surface)

    -- S|===IP   C    |  Feed active provider chest items
    environment.create_supplier { position = { -8, 0 }, direction = defines.direction.east, left_filter = "iron-gear-wheel" }
    for x = -7, -4 do
        surface.create_entity { name = "transport-belt", position = { x, 0 }, direction = defines.direction.east }
    end
    surface.create_entity { name = "fast-inserter", position = { -3, 0 }, direction = defines.direction.west }
    surface.create_entity { name = "active-provider-chest", position = { -2, 0 } }
    local storage = surface.create_entity { name = "storage-chest", position = { -2, 0 } }
    local inventory = storage.get_inventory(defines.inventory.chest)

    local sequence = new_sequence()
    sequence:event(0, function() -- Clear storage chest every 5 seconds
        inventory.clear()
    end)
    sequence:finish(300)
end

function bot_logistics.buffer_chest()
    local surface = game.surfaces[1]
    game.simulation.camera_alt_info = true
    environment.center_viewport()
    environment.create_roboport(surface, { -1, -5 })

    --  |   R B   C   |
    local storage = surface.create_entity { name = "storage-chest", position = { 3, 0 } }
    local buffer = surface.create_entity { name = "buffer-chest", position = { -1, 0 } }
    local requester = surface.create_entity { name = "requester-chest", position = { -3, 0 } }
    requester.request_from_buffers = true

    local req_section = requester.get_logistic_sections().add_section("")
    req_section.active = false
    req_section.set_slot(1, { value = "iron-gear-wheel", min = 10 })

    local buf_section = buffer.get_logistic_sections().add_section("")
    buf_section.active = false
    buf_section.set_slot(1, { value = "iron-gear-wheel", min = 10 })

    local sequence = new_sequence()
    sequence:event(0, function() -- Add items to storage
        storage.get_inventory(defines.inventory.chest)
            .insert { name = "iron-gear-wheel", count = 10 }
    end)
    sequence:event(30, function() -- Move items to buffer
        buf_section.active = true
    end)
    sequence:event(120, function() -- Move items to requester
        req_section.active = true
    end)
    sequence:event(210, function() -- Clear items and disable requests
        buf_section.active = false
        req_section.active = false
        requester.get_inventory(defines.inventory.chest)
            .clear()
    end)
    sequence:finish(270)
end

function bot_logistics.roboport(name)
    local surface = game.surfaces[1]
    local roboport = prototypes.entity[name]

    if roboport.tile_width % 2 == 1 then
        environment.center_viewport(-1)
    else
        game.simulation.camera_position = { 0, -1 }
    end
    environment.viewport_height(roboport.tile_height + 2)
    environment.setup_electricity(surface)
    environment.research_all()

    local roboport_entity = surface.create_entity { name = name, position = { 0, 0 } }
    roboport_entity.get_inventory(defines.inventory.roboport_robot).insert("construction-robot")

    local sequence = new_sequence()
    sequence:event(30, function() -- Insert solar panels, order deconstruction on them and reset chests
        environment.paste(surface, { 0, 0 }, blueprints.roboport_env)
        for _, entity in pairs(surface.find_entities_filtered { name = "storage-chest", area = { { -25, -15 }, { 25, 15 } } }) do
            entity.get_inventory(defines.inventory.chest).clear()
        end
        for _, entity in pairs(surface.find_entities_filtered { name = "solar-panel", area = { { -25, -15 }, { 25, 15 } } }) do
            entity.order_deconstruction(environment.default_force)
        end
    end)
    sequence:finish(600)
end

return bot_logistics
