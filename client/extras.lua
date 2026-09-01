local MAX_EXTRAS = 8
local extras = {}

local ICON_NAMES = {
    heart = true,
    shield = true,
    utensils = true,
    droplet = true,
    activity = true,
    fuel = true,
    seatbelt = true,
    mic = true,
    wind = true,
    waves = true,
    bolt = true,
    crosshair = true,
    star = true,
    parachute = true,
}

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

local function sanitizeColor(value)
    if type(value) ~= 'string' then
        return nil
    end
    if value:match('^#%x%x%x%x%x%x$') or value:match('^#%x%x%x$') then
        return value
    end
    local r, g, b, a = value:match('^rgba%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,%s*([%d%.]+)%s*%)$')
    if r then
        r, g, b, a = tonumber(r), tonumber(g), tonumber(b), tonumber(a)
        if r and g and b and a and r <= 255 and g <= 255 and b <= 255 and a >= 0 and a <= 1 then
            return ('rgba(%d, %d, %d, %.2f)'):format(r, g, b, a)
        end
    end
    r, g, b = value:match('^rgb%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*%)$')
    if r then
        r, g, b = tonumber(r), tonumber(g), tonumber(b)
        if r and g and b and r <= 255 and g <= 255 and b <= 255 then
            return ('rgb(%d, %d, %d)'):format(r, g, b)
        end
    end
    return nil
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
    local icon = type(opts.icon) == 'string' and ICON_NAMES[opts.icon] and opts.icon
        or (existing and existing.icon)
        or 'star'
    local color = sanitizeColor(opts.color)
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
