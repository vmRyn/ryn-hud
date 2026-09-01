RynHud = RynHud or {}

RynHud.DefaultTheme = {
    schema = 1,
    preset = 'nightGlass',
    accent = '#007BC7',
    surface = 'rgba(8, 8, 8, 0.42)',
    surfaceStrong = 'rgba(10, 10, 10, 0.92)',
    text = '#FFFFFF',
    muted = 'rgba(236, 232, 225, 0.42)',
    warning = '#C7924A',
    critical = '#D45B4A',
    blur = 10,
    radius = 4,
    statusSize = 1,
    badgeStyle = 'filled',
    badgeLayout = 'ring',
    badgeShape = 'circle',
    ringBackground = true,
    status = {
        position = 'bottom-center',
        offsetX = 1.8,
        offsetY = 2.6,
    },
    compass = {
        position = 'top-center',
        offsetX = 0,
        offsetY = 2,
    },
    identity = {
        position = 'top-right',
        offsetX = 2.2,
        offsetY = 2,
    },
    compassBackground = true,
    icons = {
        health = 'heart',
        armor = 'shield',
        hunger = 'utensils',
        thirst = 'droplet',
        stress = 'activity',
        fuel = 'fuel',
        seatbelt = 'seatbelt',
        voice = 'mic',
        stamina = 'wind',
        oxygen = 'waves',
    },
    colors = {
        health = '#D45B4A',
        armor = '#4CB8A8',
        hunger = '#D47A32',
        thirst = '#4A82C4',
        stress = '#8B6BC8',
        stamina = '#D4B46A',
        oxygen = '#5AA4B4',
        voice = '#E4DDD2',
    },
    visibility = {
        compass = true,
        money = false,
        job = false,
        radarOnFoot = false,
        peekMoney = true,
        stress = false,
        voice = true,
        voiceModeLabel = true,
        waypoint = true,
        stamina = true,
        oxygen = true,
        ammo = true,
        parachute = true,
        harness = true,
    },
    thresholds = {
        hideArmorAtZero = true,
        hideNeedsWhenFull = true,
        needsFullAt = 95,
    },
    vehicle = {
        units = 'mph',
        speedStyle = 'digitalArc',
        showGear = true,
        showFuel = true,
        showEngine = true,
        showCruise = true,
        readoutBackground = true,
        minimapShape = 'square',
    },
}

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

local BADGE_STYLES = { filled = true, outline = true, duotone = true }
local BADGE_LAYOUTS = { ring = true, percent = true, fill = true, bars = true }
local BADGE_SHAPES = { circle = true, rounded = true }
local STATUS_POSITIONS = {
    ['bottom-left'] = true,
    ['bottom-center'] = true,
    ['bottom-right'] = true,
    ['top-left'] = true,
    ['top-right'] = true,
}
local HUD_ANCHORS = {
    ['bottom-left'] = true,
    ['bottom-center'] = true,
    ['bottom-right'] = true,
    ['top-left'] = true,
    ['top-center'] = true,
    ['top-right'] = true,
}
local SPEED_STYLES = { digitalArc = true, digital = true, minimal = true, analog = true, circular = true }
local UNITS = { mph = true, kph = true }
local MINIMAP_SHAPES = { square = true, circle = true }

local function copy(value)
    if type(value) ~= 'table' then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = copy(v)
    end
    return out
end

function RynHud.DeepCopy(value)
    return copy(value)
end

local function clampNumber(value, min, max, default)
    value = tonumber(value)
    if value == nil then
        return default
    end
    if value < min then
        return min
    end
    if value > max then
        return max
    end
    return value
end

local function asBool(value, default)
    if value == nil then
        return default and true or false
    end
    return value and true or false
end

local function pick(value, allowed, default)
    if type(value) == 'string' and allowed[value] then
        return value
    end
    return default
end

local function sanitizeColor(value, default)
    if type(value) ~= 'string' then
        return default
    end
    if value:match('^#%x%x%x%x%x%x$') or value:match('^#%x%x%x$') then
        return value
    end
    local r, g, b, a = value:match('^rgba%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,%s*([%d%.]+)%s*%)$')
    if r then
        r, g, b = tonumber(r), tonumber(g), tonumber(b)
        a = tonumber(a)
        if r and g and b and a and r <= 255 and g <= 255 and b <= 255 and a >= 0 and a <= 1 then
            return ('rgba(%d, %d, %d, %.2f)'):format(r, g, b, a)
        end
        return default
    end
    r, g, b = value:match('^rgb%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*%)$')
    if r then
        r, g, b = tonumber(r), tonumber(g), tonumber(b)
        if r and g and b and r <= 255 and g <= 255 and b <= 255 then
            return ('rgb(%d, %d, %d)'):format(r, g, b)
        end
    end
    return default
end

local function sanitizePlacement(raw, default, allowed)
    raw = type(raw) == 'table' and raw or {}
    return {
        position = pick(raw.position, allowed, default.position),
        offsetX = clampNumber(raw.offsetX, 0, 8, default.offsetX),
        offsetY = clampNumber(raw.offsetY, 0, 8, default.offsetY),
    }
end

local function sanitizeMap(raw, default, valueFn)
    raw = type(raw) == 'table' and raw or {}
    local out = {}
    for key, fallback in pairs(default) do
        out[key] = valueFn(raw[key], fallback)
    end
    return out
end

function RynHud.MergeTheme(base, override, root)
    local merged = copy(base or RynHud.DefaultTheme)
    if type(override) ~= 'table' then
        if root ~= false then
            merged.schema = 1
        end
        return merged
    end

    for key, value in pairs(override) do
        if type(value) == 'table' and type(merged[key]) == 'table' then
            merged[key] = RynHud.MergeTheme(merged[key], value, false)
        elseif value ~= nil then
            merged[key] = copy(value)
        end
    end

    if root ~= false then
        merged.schema = 1
    end
    return merged
end

function RynHud.SanitizeTheme(raw)
    local d = RynHud.DefaultTheme
    raw = type(raw) == 'table' and raw or {}

    local theme = {
        schema = 1,
        preset = type(raw.preset) == 'string' and raw.preset:sub(1, 32) or d.preset,
        accent = sanitizeColor(raw.accent, d.accent),
        surface = sanitizeColor(raw.surface, d.surface),
        surfaceStrong = sanitizeColor(raw.surfaceStrong, d.surfaceStrong),
        text = sanitizeColor(raw.text, d.text),
        muted = sanitizeColor(raw.muted, d.muted),
        warning = sanitizeColor(raw.warning, d.warning),
        critical = sanitizeColor(raw.critical, d.critical),
        blur = clampNumber(raw.blur, 0, 28, d.blur),
        radius = clampNumber(raw.radius, 0, 28, d.radius),
        statusSize = clampNumber(raw.statusSize, 0.75, 1.35, d.statusSize),
        badgeStyle = pick(raw.badgeStyle, BADGE_STYLES, d.badgeStyle),
        badgeLayout = pick(raw.badgeLayout, BADGE_LAYOUTS, d.badgeLayout),
        badgeShape = pick(raw.badgeShape, BADGE_SHAPES, d.badgeShape),
        ringBackground = asBool(raw.ringBackground, d.ringBackground),
        status = sanitizePlacement(raw.status, d.status, STATUS_POSITIONS),
        compass = sanitizePlacement(raw.compass, d.compass, HUD_ANCHORS),
        identity = sanitizePlacement(raw.identity, d.identity, HUD_ANCHORS),
        compassBackground = asBool(raw.compassBackground, d.compassBackground),
        icons = sanitizeMap(raw.icons, d.icons, function(value, fallback)
            return pick(value, ICON_NAMES, fallback)
        end),
        colors = sanitizeMap(raw.colors, d.colors, sanitizeColor),
        visibility = sanitizeMap(raw.visibility, d.visibility, asBool),
        thresholds = {
            hideArmorAtZero = asBool(raw.thresholds and raw.thresholds.hideArmorAtZero, d.thresholds.hideArmorAtZero),
            hideNeedsWhenFull = asBool(raw.thresholds and raw.thresholds.hideNeedsWhenFull, d.thresholds.hideNeedsWhenFull),
            needsFullAt = clampNumber(raw.thresholds and raw.thresholds.needsFullAt, 80, 100, d.thresholds.needsFullAt),
        },
        vehicle = {
            units = pick(raw.vehicle and raw.vehicle.units, UNITS, d.vehicle.units),
            speedStyle = pick(raw.vehicle and raw.vehicle.speedStyle, SPEED_STYLES, d.vehicle.speedStyle),
            showGear = asBool(raw.vehicle and raw.vehicle.showGear, d.vehicle.showGear),
            showFuel = asBool(raw.vehicle and raw.vehicle.showFuel, d.vehicle.showFuel),
            showEngine = asBool(raw.vehicle and raw.vehicle.showEngine, d.vehicle.showEngine),
            showCruise = asBool(raw.vehicle and raw.vehicle.showCruise, d.vehicle.showCruise),
            readoutBackground = asBool(raw.vehicle and raw.vehicle.readoutBackground, d.vehicle.readoutBackground),
            minimapShape = pick(raw.vehicle and raw.vehicle.minimapShape, MINIMAP_SHAPES, d.vehicle.minimapShape),
        },
    }

    return theme
end

function RynHud.IsAllowedIcon(name)
    return type(name) == 'string' and ICON_NAMES[name] == true
end

function RynHud.SanitizeColor(value, default)
    return sanitizeColor(value, default)
end
