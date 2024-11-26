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
---@param length uint Loop length
---@param delay uint? Event start offset
function EventSequence:finish(length, delay)
    function run(event)
        local tick = event.tick - (delay or 0)
        local modulo = tick % length
        local actions = self.events[modulo]
        if not actions then return end
        for _, action in pairs(actions) do
            action()
        end
    end

    if delay then
        script.on_nth_tick(delay, function(data)
            if data.tick == 0 then return end
            script.on_nth_tick(delay, nil)
            script.on_event(defines.events.on_tick, run)
        end)
    else
        script.on_event(defines.events.on_tick, run)
    end
end

---@return EventSequence
function new_sequence()
    local self = setmetatable({}, EventSequence)
    self.events = {}
    return self
end
