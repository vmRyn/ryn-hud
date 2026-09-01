local hideToken = 0
local radarVisible = false
local lastInVehicle = false
local lastRadarOnFoot = false
local lastCinematic = false
local lastHudVisible = true
local lastObscured = false
local lastMapShape = nil
local shapeToken = 0

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

function RynHud.ApplyMinimapShape()
    local circle = themeCircleMap()
    if lastMapShape == circle then
        return
    end
    local restore = lastMapShape == true and not circle
    lastMapShape = circle
    if not circle and not restore then
        return
    end

    shapeToken = shapeToken + 1
    local token = shapeToken
    CreateThread(function()
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
        if token ~= shapeToken then
            return
        end
        refreshMinimapLayout()
    end)
end

local function queueRadar(show, delay)
    hideToken = hideToken + 1
    local token = hideToken
    CreateThread(function()
        Wait(delay)
        if token ~= hideToken then
            return
        end
        radarVisible = show
        DisplayRadar(show)
    end)
end

CreateThread(function()
    while true do
        local inVehicle = IsPedInAnyVehicle(PlayerPedId(), false)
        local radarOnFoot = themeRadarOnFoot()

        if not radarAllowed() then
            if radarVisible then
                radarVisible = false
                DisplayRadar(false)
            end
        elseif (lastCinematic and not RynHud.Cinematic)
            or (lastHudVisible == false and RynHud.HudVisible ~= false)
            or (lastObscured and not RynHud.Obscured) then
            if inVehicle then
                RynHud.VehicleVisible = true
                RynHud.SendNui('setVehicleScene', { active = true })
                queueRadar(true, Config.MinimapDelayMs or 80)
            else
                RynHud.VehicleVisible = false
                RynHud.SendNui('setVehicleScene', { active = false })
                queueRadar(radarOnFoot, 0)
            end
        elseif inVehicle and not lastInVehicle then
            RynHud.VehicleVisible = true
            RynHud.SendNui('setVehicleScene', { active = true })
            queueRadar(true, Config.MinimapDelayMs or 80)
        elseif not inVehicle and lastInVehicle then
            RynHud.VehicleVisible = false
            RynHud.SendNui('setVehicleScene', { active = false })
            if radarOnFoot then
                queueRadar(true, 0)
            else
                queueRadar(false, Config.RadarHideAfterExitMs or 420)
            end
        elseif radarOnFoot ~= lastRadarOnFoot and not inVehicle then
            radarVisible = radarOnFoot
            DisplayRadar(radarOnFoot)
        end

        lastInVehicle = inVehicle
        lastRadarOnFoot = radarOnFoot
        lastCinematic = RynHud.Cinematic == true
        lastHudVisible = RynHud.HudVisible ~= false
        lastObscured = RynHud.Obscured == true
        Wait(100)
    end
end)
