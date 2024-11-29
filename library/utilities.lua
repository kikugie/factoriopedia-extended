local utilities = {}

--- Provides an iterator over the given bounding box.
---@param box BoundingBox
---@return fun(): (number, number)|nil
function utilities.box(box)
    local x0, y0 = box[1][1], box[1][2]
    local x1, y1 = box[2][1], box[2][2]

    local x, y = x0, y0
    return function()
        if x >= x1 then
            x = x0
            y = y + 1
        end
        if y >= y1 then
            return nil
        end
        local current_x, current_y = x, y
        x = x + 1
        return current_x, current_y
    end
end

--- Collects values from a table into an array with the given function.
---@generic K, V, R
---@param source table<K, V>
---@param transform fun(key: K, value: V): R?
---@return R[]
function utilities.collect(source, transform)
    local result = {}
    for key, value in pairs(source) do
        local it = transform(key, value)
        if it then table.insert(result, it) end
    end
    return result
end

---@param direction defines.direction
---@return MapPosition
function utilities.to_map_position(direction)
    if direction == defines.direction.east then
        return { 1, 0, x = 1, y = 0 }
    elseif direction == defines.direction.north then
        return { 0, -1, x = 0, y = -1 }
    elseif direction == defines.direction.south then
        return { 0, 1, x = 0, y = 1 }
    else
        return { -1, 0, x = -1, y = 1 }
    end
end

return utilities
