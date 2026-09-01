RynHud = RynHud or {}
RynHud.Theme = RynHud.SanitizeTheme(RynHud.DefaultTheme)

local lastSent = {}

local function valuesEqual(a, b)
    if a == b then
        return true
    end
    if type(a) ~= 'table' or type(b) ~= 'table' then
        return false
    end
    for k, v in pairs(a) do
        if not valuesEqual(v, b[k]) then
            return false
        end
    end
    for k in pairs(b) do
        if a[k] == nil then
            return false
        end
    end
    return true
end

local function round(value)
    if type(value) ~= 'number' then
        return value
    end
    return math.floor(value + 0.5)
end

function RynHud.Round(value)
    return round(value)
end

function RynHud.Clamp(value, min, max)
    value = tonumber(value) or 0
    if value < min then
        return min
    end
    if value > max then
        return max
    end
    return value
end

function RynHud.Notify(key)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(L(key))
    EndTextCommandThefeedPostTicker(false, true)
end

function RynHud.SendNui(action, data)
    SendNUIMessage({
        action = action,
        data = data,
    })
end

function RynHud.PatchState(patch)
    local diff = {}
    local changed = false
    for key, value in pairs(patch) do
        if not valuesEqual(lastSent[key], value) then
            diff[key] = value
            lastSent[key] = RynHud.DeepCopy(value)
            changed = true
        end
    end
    if changed then
        RynHud.SendNui('patchState', diff)
    end
end

function RynHud.ForceState(state)
    lastSent = RynHud.DeepCopy(state) or {}
    RynHud.SendNui('setState', state)
end

function RynHud.ApplyTheme(theme)
    RynHud.Theme = RynHud.SanitizeTheme(theme)
    RynHud.SendNui('setTheme', RynHud.Theme)
    if RynHud.ApplyMinimapShape then
        RynHud.ApplyMinimapShape()
    end
end

exports('GetTheme', function()
    return RynHud.Theme
end)
