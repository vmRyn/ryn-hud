local seq = 0
local active = 0

local TYPES = {
    info = true,
    success = true,
    warning = true,
    error = true,
    announce = true,
}

local POSITIONS = {
    ['top-left'] = true,
    ['top-right'] = true,
    ['bottom-left'] = true,
    ['bottom-right'] = true,
}

local function cfg()
    local c = Config.Notifications
    if type(c) ~= 'table' then
        return {
            enabled = c ~= false,
            position = 'top-right',
            offsetX = 2.2,
            offsetY = 2.0,
            maxVisible = 5,
            defaultDuration = 5000,
            maxDuration = 20000,
        }
    end
    return c
end

local function enabled()
    return cfg().enabled ~= false
end

local function pushConfig()
    if not RynHud.SendNui then
        return
    end
    local c = cfg()
    local position = POSITIONS[c.position] and c.position or 'top-right'
    RynHud.SendNui('setNotifyConfig', {
        enabled = c.enabled ~= false,
        position = position,
        offsetX = RynHud.Clamp(tonumber(c.offsetX) or 2.2, 0, 12),
        offsetY = RynHud.Clamp(tonumber(c.offsetY) or 2.0, 0, 12),
        maxVisible = math.floor(RynHud.Clamp(tonumber(c.maxVisible) or 5, 1, 8)),
        sound = c.sound ~= false,
        soundVolume = RynHud.Clamp(tonumber(c.soundVolume) or 0.4, 0, 1),
    })
end

local function sanitizeType(value)
    if type(value) == 'string' and TYPES[value:lower()] then
        return value:lower()
    end
    return 'info'
end

local function sanitizeText(value, maxLen)
    if type(value) ~= 'string' then
        return nil
    end
    value = value:gsub('%s+', ' '):match('^%s*(.-)%s*$') or ''
    if value == '' then
        return nil
    end
    if #value > maxLen then
        value = value:sub(1, maxLen)
    end
    return value
end

local function showNotification(data, maybeType, maybeDuration)
    if not enabled() then
        return false
    end

    local opts = {}
    if type(data) == 'string' then
        opts.message = data
        if type(maybeType) == 'string' then
            opts.type = maybeType
        elseif type(maybeType) == 'table' then
            opts = maybeType
            opts.message = data
        end
        if type(maybeDuration) == 'number' then
            opts.duration = maybeDuration
        end
    elseif type(data) == 'table' then
        opts = data
    else
        return false
    end

    local message = sanitizeText(opts.message or opts.description or opts.text, 220)
    if not message then
        return false
    end

    local title = sanitizeText(opts.title or opts.header, 48)
    local nType = sanitizeType(opts.type or opts.level or 'info')
    local c = cfg()
    local defaultDuration = tonumber(c.defaultDuration) or 5000
    local maxDuration = tonumber(c.maxDuration) or 20000
    local duration = tonumber(opts.duration) or defaultDuration
    duration = math.floor(RynHud.Clamp(duration, 1200, maxDuration))

    local icon = opts.icon
    if icon and not (RynHud.IsAllowedIcon and RynHud.IsAllowedIcon(icon)) then
        icon = nil
    end

    local color = RynHud.SanitizeColor and RynHud.SanitizeColor(opts.color, nil) or nil

    seq = seq + 1
    active = active + 1
    local id = ('n-%d-%d'):format(GetGameTimer(), seq)

    RynHud.SendNui('notify', {
        id = id,
        title = title,
        message = message,
        type = nType,
        duration = duration,
        icon = icon,
        color = color,
    })

    SetTimeout(duration + 400, function()
        active = math.max(0, active - 1)
    end)

    return id
end

local function clearNotifications()
    if not enabled() then
        return false
    end
    active = 0
    RynHud.SendNui('clearNotifications')
    return true
end

local function announce(data, maybeDuration)
    if type(data) == 'string' then
        return showNotification({
            message = data,
            type = 'announce',
            title = 'Announcement',
            duration = maybeDuration,
        })
    end
    if type(data) == 'table' then
        data = RynHud.DeepCopy(data) or data
        data.type = 'announce'
        if not data.title then
            data.title = 'Announcement'
        end
        return showNotification(data)
    end
    return false
end

RynHud.ShowNotification = showNotification
RynHud.ClearNotifications = clearNotifications
RynHud.PushNotifyConfig = pushConfig

exports('Notify', showNotification)
exports('Announce', announce)
exports('ClearNotifications', clearNotifications)

RegisterNetEvent('ryn-hud:client:notify', function(data, maybeType, maybeDuration)
    showNotification(data, maybeType, maybeDuration)
end)

RegisterNetEvent('ryn-hud:client:announce', function(data, maybeDuration)
    announce(data, maybeDuration)
end)

RegisterNetEvent('ryn-hud:client:clearNotifications', function()
    clearNotifications()
end)

AddEventHandler('ryn-hud:client:nuiReady', function()
    pushConfig()
end)

CreateThread(function()
    Wait(0)
    pushConfig()
end)
