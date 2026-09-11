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
    local nA, nB = 0, 0
    for k, v in pairs(a) do
        nA = nA + 1
        if not valuesEqual(v, b[k]) then
            return false
        end
    end
    for _ in pairs(b) do
        nB = nB + 1
    end
    return nA == nB
end

-- Shallow copy for flat HUD patches (vehicle/voice/identity/compass leaves).
local function copyValue(value)
    if type(value) ~= 'table' then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        if type(v) == 'table' then
            local nested = {}
            for nk, nv in pairs(v) do
                nested[nk] = nv
            end
            out[k] = nested
        else
            out[k] = v
        end
    end
    return out
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

--- True when status/vehicle/contextual patches should hit NUI.
function RynHud.ShouldPushHud()
    return RynHud.Loaded
        and RynHud.HudVisible ~= false
        and not RynHud.Cinematic
        and not RynHud.Obscured
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
            lastSent[key] = copyValue(value)
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
