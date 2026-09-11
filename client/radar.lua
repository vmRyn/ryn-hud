local hideToken = 0
local radarVisible = false
local expectRadar = false
local lastInVehicle = false
local lastMapShape = nil
local shapeToken = 0
local layoutReady = false

local function radarAllowed()
    return not RynHud.Cinematic and RynHud.HudVisible ~= false and not RynHud.Obscured
end

local function themeRadarOnFoot()
    return RynHud.Theme and RynHud.Theme.visibility and RynHud.Theme.visibility.radarOnFoot == true
end

local function themeCircleMap()
    return RynHud.Theme and RynHud.Theme.vehicle and RynHud.Theme.vehicle.minimapShape == 'circle'
end

local function minimapOffset()
    local resX, resY = GetActiveScreenResolution()
    if not resY or resY == 0 then
        return 0.0
    end
    local aspect = resX / resY
    local defaultAspect = 1920 / 1080
    if aspect > defaultAspect then
        return ((defaultAspect - aspect) / 3.6) - 0.008
    end
    return 0.0
end

local function refreshMinimapLayout()
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
end

local function applyShapePositions(circle)
    local offset = minimapOffset()
    if circle then
        pcall(SetMinimapClipType, 1)
        SetMinimapComponentPosition('minimap', 'L', 'B', -0.008 + offset, -0.025, 0.148, 0.188)
        SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.010 + offset, 0.032, 0.111, 0.159)
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.018 + offset, 0.018, 0.180, 0.230)
    else
        pcall(SetMinimapClipType, 0)
        SetMinimapComponentPosition('minimap', 'L', 'B', 0.0 + offset, -0.047, 0.1638, 0.183)
        SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.0 + offset, 0.0, 0.128, 0.20)
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.01 + offset, 0.025, 0.262, 0.300)
    end
end

--- @param force boolean|nil
function RynHud.ApplyMinimapShape(force)
    local circle = themeCircleMap()
    if not force and layoutReady and lastMapShape == circle then
        return
    end

    lastMapShape = circle
    shapeToken = shapeToken + 1
    local token = shapeToken
    CreateThread(function()
        applyShapePositions(circle)
        if token ~= shapeToken then
            return
        end
        refreshMinimapLayout()
        Wait(50)
        if token ~= shapeToken then
            return
        end
        refreshMinimapLayout()
        layoutReady = true
    end)
end

local function setRadar(show)
    show = show and true or false
    radarVisible = show
    DisplayRadar(show)
end

local function queueRadar(show, delay)
    hideToken = hideToken + 1
    local token = hideToken
    show = show and true or false
    expectRadar = show
    CreateThread(function()
        if delay and delay > 0 then
            Wait(delay)
        end
        if token ~= hideToken then
            return
        end
        setRadar(show)
        if show then
            refreshMinimapLayout()
        end
    end)
end

local function desiredRadar(inVehicle)
    if not radarAllowed() then
        return false
    end
    if inVehicle then
        return true
    end
    return themeRadarOnFoot()
end

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(250)
    end
    Wait(750)
    RynHud.ApplyMinimapShape(true)
end)

CreateThread(function()
    while true do
        local wait = 100
        local inVehicle = IsPedInAnyVehicle(PlayerPedId(), false)
        local want = desiredRadar(inVehicle)

        if inVehicle and not lastInVehicle then
            RynHud.VehicleVisible = true
            RynHud.SendNui('setVehicleScene', { active = true })
            RynHud.ApplyMinimapShape(true)
            queueRadar(true, Config.MinimapDelayMs or 80)
        elseif not inVehicle and lastInVehicle then
            RynHud.VehicleVisible = false
            RynHud.SendNui('setVehicleScene', { active = false })
            if want then
                queueRadar(true, 0)
            else
                queueRadar(false, Config.RadarHideAfterExitMs or 420)
            end
        elseif want ~= expectRadar then
            if want then
                queueRadar(true, inVehicle and (Config.MinimapDelayMs or 80) or 0)
            else
                hideToken = hideToken + 1
                expectRadar = false
                setRadar(false)
            end
        elseif want and inVehicle then
            DisplayRadar(true)
            radarVisible = true
            wait = 200
        end

        lastInVehicle = inVehicle
        Wait(wait)
    end
end)
