local vector = {}

local function convert_direction(direction)
    -- Lookup for cardinal directions
    if direction == defines.direction.north then
        return { 0, -1 }
    elseif direction == defines.direction.west then
        return { 1, 0 }
    elseif direction == defines.direction.south then
        return { 0, 1 }
    elseif direction == defines.direction.south then
        return { -1, 0 }
    end

    local angle = direction / 8 * math.pi
    return { math.sin(angle), -math.cos(angle) }
end

local function rotate_vector(vec, angle)
    local fixed = vector.standardize(vec)
    -- Cardinal directions can have simplified rotation logic
    if angle == 0 then
        return vec
    elseif angle == 90 then
        return { fixed.y, -fixed.x }
    elseif angle == 180 then
        return { -fixed.x, -fixed.y }
    elseif angle == 270 or angle == -90 then
        return { -fixed.y, fixed.x }
    end

    local cos = math.cos(math.rad(angle))
    local sin = math.sin(math.rad(angle))
    return { cos * fixed.x - sin * fixed.y, sin * fixed.x + cos * fixed.y }
end

---@param vec any
---@return Vector
function vector.standardize(vec)
    local x = vec.x or vec[1]
    local y = vec.y or vec[2]
    return { x, y, x = x, y = y }
end

---@param direction defines.direction
---@return Vector
function vector.from_direction(direction)
    return vector.standardize(convert_direction(direction))
end

---@param vec Vector
---@return defines.direction
function vector.to_direction(vec)
    local fix = vector.standardize(vec)
    if fix.x == 0 and fix.y == 0 then
        error("Zero vector can't be converted to a direction")
    elseif fix.x == 0 then
        if fix.y < 0 then
            return defines.direction.north
        else
            return defines.direction.south
        end
    elseif fix.y == 0 then
        if fix.x < 0 then
            return defines.direction.west
        else
            return defines.direction.east
        end
    end

    local normalized = vector.normalize(vec)
    local angle = math.atan(normalized.x, -normalized.y)
    return math.floor((angle / (2 * math.pi)) * 16 + 0.5) % 16 --[[@as defines.direction]]
end

---@param vec Vector
---@param direction defines.direction
---@param multiplier number?
---@return Vector
function vector.offset(vec, direction, multiplier)
    local fixed = vector.standardize(vec)
    local offset = vector.from_direction(direction)
    local mult = multiplier or 1
    return vector.standardize { fixed.x + offset.x * mult, fixed.y + offset.y * mult }
end

---@param vec Vector
---@param angle number
---@return Vector
function vector.rotate(vec, angle)
    return vector.standardize(rotate_vector(vec, angle))
end

---@param vec1 Vector
---@param vec2 Vector
---@return Vector
function vector.add(vec1, vec2)
    local fix1 = vector.standardize(vec1)
    local fix2 = vector.standardize(vec2)
    return vector.standardize { fix1.x + fix2.x, fix1.y + fix2.y }
end

---@param vec1 Vector
---@param vec2 Vector
---@return Vector
function vector.sub(vec1, vec2)
    local fix1 = vector.standardize(vec1)
    local fix2 = vector.standardize(vec2)
    return vector.standardize { fix1.x - fix2.x, fix1.y - fix2.y }
end

---@param vec Vector
---@param scalar number
---@return Vector
function vector.mul(vec, scalar)
    local fix = vector.standardize(vec)
    return vector.standardize { fix.x * scalar, fix.y * scalar }
end

---@param vec Vector
---@return Vector
function vector.invert(vec)
    local fix = vector.standardize(vec)
    return vector.standardize { -fix.x, -fix.y }
end

---@param vec Vector
---@return Vector
function vector.normalize(vec)
    local fix = vector.standardize(vec)
    local length = math.sqrt(fix.x * fix.x + vec.y * vec.y)
    return vector.standardize { fix.x / length, fix.y / length }
end

return vector
