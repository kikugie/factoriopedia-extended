--- Stores events scheduled for specific ticks and executes them on the provided interval.
---@class EventSequence
---@field events { [integer]: function[] }
EventSequence = {}
EventSequence.__index = EventSequence

--- Adds a new event on the specified tick. This can be called multiple times for the same tick.
---@param tick integer
---@param action function
function EventSequence:event(tick, action)
    local actions = self.events[tick]
    if not actions then
        actions = {}
        self.events[tick] = actions
    end
    table.insert(actions, action)
end

--- Registers this sequence in the `on_tick` event.
function EventSequence:finish(length)
    script.on_event(defines.events.on_tick, function(event)
        local tick = event.tick
        local modulo = tick % length
        local actions = self.events[modulo]
        if not actions then return end
        for _, action in pairs(actions) do
            action()
        end
    end)
end

---@return EventSequence
function new_sequence()
    local self = setmetatable({}, EventSequence)
    self.events = {}
    return self
end
