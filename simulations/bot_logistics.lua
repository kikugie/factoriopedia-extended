---@diagnostic disable: need-check-nil
require "library.story"
local environment = require "library.environment"
local blueprints  = require "blueprints"
local logistics   = {}

function logistics.storage_chest()
    local surface = game.surfaces[1]
    environment.center_viewport()
    environment.roboport(surface, { 0, -5 })
    environment.container(surface, "storage-chest", { -2, 0 }, { name = "small-lamp", count = 1 })
    environment.setup_electricity(surface)
    game.simulation.camera_alt_info = true
    local blueprint = environment.blueprint(blueprints.storage_chest)

    local sequence = new_sequence()
    sequence:event(30, function()
        -- Build green lamp from the chest
        blueprint.build_blueprint { surface = surface, position = { 2, 0 }, force = "enemy" }
    end)
    sequence:event(180, function()
        -- Remove the lamp and store the item
        surface.deconstruct_area { area = { { 2, 0 }, { 2, 0 } }, force = "enemy" }
    end)
    sequence:finish(360)
end

function logistics.requester_chest()
    local surface = game.surfaces[1]
    environment.center_viewport()
    environment.roboport(surface, { -1, -5 })
    game.simulation.camera_alt_info = true

    local requester = environment.container(surface, "requester-chest", { -2, 0 })
    local storage = environment.container(surface, "storage-chest", { 2, 0 })
    ---@type LuaLogisticSection
    local section = requester.get_logistic_sections().add_section("")
    section.active = false
    section.set_slot(1, { value = "iron-gear-wheel", min = 10 })

    local sequence = new_sequence()
    sequence:event(0, function()
        -- Add gears to storage to be delivered to the requester
        storage.get_inventory(defines.inventory.chest)
            .insert { name = "iron-gear-wheel", count = 10 }
    end)
    sequence:event(30, function()
        -- Move gears to the requester
        section.active = true
    end)
    sequence:event(180, function()
        -- Disable the request and clear the inventory
        section.active = false
        requester.get_inventory(defines.inventory.chest)
            .clear()
    end)
    sequence:finish(240)
end

function logistics.passive_provider_chest()
    local surface = game.surfaces[1]
    game.simulation.camera_alt_info = true
    environment.center_viewport()
    environment.roboport(surface, { -1, -5 })

    local storage = environment.container(surface, "passive-provider-chest", { -2, 0 })
    local requester = environment.container(surface, "requester-chest", { 2, 0 })
    ---@type LuaLogisticSection
    local section = requester.get_logistic_sections().add_section("")
    section.active = false
    section.set_slot(1, { value = "iron-gear-wheel", min = 10 })

    local sequence = new_sequence()
    sequence:event(0, function()
        -- Add gears to storage to be delivered to the requester
        storage.get_inventory(defines.inventory.chest)
            .insert { name = "iron-gear-wheel", count = 10 }
    end)
    sequence:event(30, function()
        -- Move gears to the requester
        section.active = true
    end)
    sequence:event(180, function()
        -- Disable the request and clear the inventory
        section.active = false
        requester.get_inventory(defines.inventory.chest)
            .clear()
    end)
    sequence:finish(240)
end

function logistics.active_provider_chest()
    local surface = game.surfaces[1]
    environment.roboport(surface, { -1, -5 })
    environment.paste(surface, { -3, 0 }, blueprints.active_provider_chest)
    environment.setup_electricity(surface)
    game.simulation.camera_alt_info = true

    local generators = surface.find_entities_filtered { name = "wooden-chest", area = { { -10, -5 }, { 0, 5 } }, }
    local chest = surface.find_entities_filtered { name = "storage-chest", area = { { -1, -3 }, { 4, 3 } }, }[1]
    local inventory = chest.get_inventory(defines.inventory.chest)

    local sequence = new_sequence()
    sequence:event(0, function()
        inventory.clear()
        -- TODO use infinity chests and speedy inserters instead
        for _, entity in pairs(generators) do
            local inv = entity.get_inventory(defines.inventory.chest)
            inv.clear()
            inv.insert("iron-gear-wheel")
        end
    end)
    sequence:finish(120)
end

function logistics.buffer_chest()
    local surface = game.surfaces[1]
    game.simulation.camera_alt_info = true
    environment.center_viewport()
    environment.roboport(surface, { -1, -5 })

    local storage = environment.container(surface, "storage-chest", { 3, 0 })
    local buffer = environment.container(surface, "buffer-chest", { -1, 0 })
    local requester = environment.container(surface, "requester-chest", { -3, 0 })
    requester.request_from_buffers = true

    ---@type LuaLogisticSection
    local req_section = requester.get_logistic_sections().add_section("")
    req_section.active = false
    req_section.set_slot(1, { value = "iron-gear-wheel", min = 10 })

    ---@type LuaLogisticSection
    local buf_section = buffer.get_logistic_sections().add_section("")
    buf_section.active = false
    buf_section.set_slot(1, { value = "iron-gear-wheel", min = 10 })

    local sequence = new_sequence()
    sequence:event(0, function()
        storage.get_inventory(defines.inventory.chest)
            .insert { name = "iron-gear-wheel", count = 10 }
    end)
    sequence:event(30, function()
        buf_section.active = true
    end)
    sequence:event(120, function()
        req_section.active = true
    end)
    sequence:event(210, function()
        buf_section.active = false
        req_section.active = false
        requester.get_inventory(defines.inventory.chest)
            .clear()
    end)
    sequence:finish(270)
end

return logistics