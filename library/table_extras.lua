local table_extras = {}

---@generic T
---@param array T[]
---@param items T[]
function table_extras.insert_all(array, items)
    for _, value in pairs(items) do
        table.insert(array, value)
    end
end

---@generic K, V, R
---@param source table<K, V>
---@param transform fun(key: K, value: V): R|nil
---@return R[]
function table_extras.collect(source, transform)
    local result = {}
    for key, value in pairs(source) do
        local it = transform(key, value)
        if it ~= nil then table.insert(result, it) end
    end
    return result
end

---@generic K, V
---@param source table<K, V>
---@param predicate fun(key: K, value: V): boolean|nil
---@return V|nil
function table_extras.find_value(source, predicate)
    for key, value in pairs(source) do
        if predicate(key, value) then return value end
    end
end

---@generic K, V
---@param source table<K, V>
---@param predicate fun(key: K, value: V): boolean|nil
---@return K|nil
function table_extras.find_key(source, predicate)
    for key, value in pairs(source) do
        if predicate(key, value) then return key end
    end
end

return table_extras
