local MAX_EXTRAS = 8
local extras = {}

local RESERVED = {
    health = true,
    armor = true,
    hunger = true,
    thirst = true,
    stress = true,
    voice = true,
    stamina = true,
    oxygen = true,
    parachute = true,
    harness = true,
    ammo = true,
}

local function sanitizeId(id)
    if type(id) ~= 'string' then
        return nil
    end
    id = id:lower():gsub('[^%w_%-]', ''):sub(1, 24)
    if id == '' or RESERVED[id] then
        return nil
    end
    return id
end

local function extrasList()
    local keys = {}
    for id in pairs(extras) do
        keys[#keys + 1] = id
    end
    table.sort(keys)
    local list = {}
    for i = 1, #keys do
        local item = extras[keys[i]]
        if not (item.hideWhenFull and item.value >= 95) then
            list[#list + 1] = {
                id = item.id,
                value = item.value,
                icon = item.icon,
                color = item.color,
            }
        end
    end
    return list
end

local function pushExtras()
    if not RynHud.PatchState then
        return
    end
    RynHud.PatchState({ extras = extrasList() })
end

local function setStatus(id, data)
    id = sanitizeId(id)
    if not id then
        return false
    end

    local value = data
    local opts = {}
    if type(data) == 'table' then
        opts = data
        value = data.value
    end
    if type(data) == 'boolean' and data == false then
        extras[id] = nil
        pushExtras()
        return true
    end

    value = RynHud.Clamp(tonumber(value) or 0, 0, 100)
    local existing = extras[id]
    local icon = (RynHud.IsAllowedIcon and RynHud.IsAllowedIcon(opts.icon) and opts.icon)
        or (existing and existing.icon)
        or 'star'
    local color = RynHud.SanitizeColor(opts.color, nil)
        or (existing and existing.color)
        or (RynHud.Theme and RynHud.Theme.accent)
        or '#007BC7'
    local hideWhenFull = existing and existing.hideWhenFull or false
    if opts.hideWhenFull ~= nil then
        hideWhenFull = opts.hideWhenFull == true
    end

    if extras[id] == nil then
        local count = 0
        for _ in pairs(extras) do
            count = count + 1
        end
        if count >= MAX_EXTRAS then
            return false
        end
    end

    extras[id] = {
        id = id,
        value = RynHud.Round(value),
        icon = icon,
        color = color,
        hideWhenFull = hideWhenFull,
    }
    pushExtras()
    return true
end

local function removeStatus(id)
    id = sanitizeId(id)
    if not id or not extras[id] then
        return false
    end
    extras[id] = nil
    pushExtras()
    return true
end

local function clearStatuses()
    extras = {}
    pushExtras()
end

exports('SetStatus', setStatus)
exports('AddStatus', setStatus)
exports('RemoveStatus', removeStatus)
exports('ClearStatuses', clearStatuses)
exports('GetStatuses', extrasList)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        extras = {}
    end
end)
