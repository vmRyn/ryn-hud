local RESOURCE = GetCurrentResourceName()
local THEME_FILE = 'data/theme.json'

local function readThemeFile()
    local raw = LoadResourceFile(RESOURCE, THEME_FILE)
    if not raw or raw == '' then
        return nil
    end
    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        return nil
    end
    return decoded
end

local function decodeKvp()
    local kvp = GetResourceKvpString('ryn-hud:theme')
    if not kvp or kvp == '' then
        return nil
    end
    local ok, decoded = pcall(json.decode, kvp)
    if not ok or type(decoded) ~= 'table' then
        return nil
    end
    return decoded
end

local function persist(theme)
    local payload = json.encode(theme)
    SaveResourceFile(RESOURCE, THEME_FILE, payload, -1)
    SetResourceKvp('ryn-hud:theme', payload)
end

local stored = RynHud.SanitizeTheme(decodeKvp() or readThemeFile() or RynHud.DefaultTheme)

function RynHud.GetStoredTheme()
    return stored
end

function RynHud.SaveTheme(theme)
    stored = RynHud.SanitizeTheme(theme)
    persist(stored)
    return stored
end

function RynHud.ResetTheme()
    DeleteResourceKvp('ryn-hud:theme')
    stored = RynHud.SanitizeTheme(RynHud.DefaultTheme)
    persist(stored)
    return stored
end
