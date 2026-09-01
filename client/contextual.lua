local talking = false
local voiceMode = 2
local radio = false
local peekUntil = 0

local directions = { 'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW' }

local function headingLabel(heading)
    local index = math.floor(((heading + 22.5) % 360) / 45) + 1
    return directions[index] or 'N'
end

local function cleanLabel(value)
    if type(value) ~= 'string' or value == '' or value == 'NULL' or value == 'null' then
        return ''
    end
    return value
end

local function getWaypointData(coords, heading)
    if not IsWaypointActive() then
        return nil
    end

    local blip = GetFirstBlipInfoId(8)
    if not blip or blip == 0 then
        return nil
    end

    local coord = GetBlipInfoIdCoord(blip)
    local wx = coord.x
    local wy = coord.y
    if not wx or not wy or (wx == 0.0 and wy == 0.0) then
        return nil
    end

    local dx = wx - coords.x
    local dy = wy - coords.y
    local distance = math.sqrt((dx * dx) + (dy * dy))
    local bearing = math.deg(math.atan(dx, dy))
    if bearing < 0 then
        bearing = bearing + 360
    end

    local relative = (bearing - heading + 360) % 360
    return {
        active = true,
        distance = RynHud.Round(distance),
        direction = headingLabel(relative),
    }
end

local function weaponUsesAmmo(ped, hash)
    local okClip, maxClip = GetMaxAmmoInClip(ped, hash)
    if okClip and maxClip > 0 then
        return true
    end
    local okAmmo, maxAmmo = GetMaxAmmo(ped, hash)
    return okAmmo and maxAmmo > 0
end

local function currentWeapon(ped)
    local _, hash = GetCurrentPedWeapon(ped, true)
    if not hash or hash == `WEAPON_UNARMED` then
        return nil
    end

    local clip = 0
    local okClip, ammoInClip = GetAmmoInClip(ped, hash)
    if okClip then
        clip = ammoInClip
    end

    local total = GetAmmoInPedWeapon(ped, hash)
    local reserve = total - clip
    if reserve < 0 then
        reserve = 0
    end

    return {
        show = true,
        hash = hash,
        clip = clip,
        reserve = reserve,
        hasAmmo = weaponUsesAmmo(ped, hash),
    }
end

local function readVoiceMode()
    local proximity = LocalPlayer.state.proximity
    if type(proximity) == 'table' then
        if type(proximity.index) == 'number' then
            return proximity.index
        end
        if type(proximity.mode) == 'number' then
            return proximity.mode
        end
        return voiceMode
    end
    if type(proximity) == 'number' then
        return proximity
    end
    return voiceMode
end

RegisterNetEvent('pma-voice:setTalkingMode', function(mode)
    voiceMode = tonumber(mode) or voiceMode
end)

RegisterNetEvent('pma-voice:radioActive', function(active)
    radio = active and true or false
end)

RegisterCommand(Config.PeekCommand, function()
    peekUntil = GetGameTimer() + 3500
    RynHud.Peeking = true
end, false)

CreateThread(function()
    while true do
        if RynHud.Loaded then
            local ped = PlayerPedId()
            local player = PlayerId()
            talking = NetworkIsPlayerTalking(player)
            local mumbleOk, mumbleTalking = pcall(MumbleIsPlayerTalking, player)
            if mumbleOk then
                talking = talking or mumbleTalking
            end

            local stamina = GetPlayerSprintStaminaRemaining(player)
            local underWater = IsPedSwimmingUnderWater(ped)
            local oxygen = 100
            if underWater then
                oxygen = RynHud.Round(RynHud.Clamp(GetPlayerUnderwaterTimeRemaining(player) * 10.0, 0, 100))
            end

            local parachuteState = GetPedParachuteState(ped)
            local weapon = currentWeapon(ped)
            local harness = LocalPlayer.state.harness == true
            voiceMode = readVoiceMode()

            RynHud.PatchState({
                voice = {
                    talking = talking,
                    mode = voiceMode,
                    radio = radio,
                },
                stamina = RynHud.Round(stamina),
                staminaActive = stamina < 95.0 and not IsPedInAnyVehicle(ped, false),
                oxygen = oxygen,
                oxygenActive = underWater,
                weapon = weapon,
                parachute = parachuteState ~= -1,
                harness = harness,
            })
        end
        Wait(150)
    end
end)

CreateThread(function()
    while true do
        local wait = Config.CompassTick or 400
        local showCompass = RynHud.Theme and RynHud.Theme.visibility and RynHud.Theme.visibility.compass
        if RynHud.Loaded and showCompass then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
            local street = cleanLabel(GetStreetNameFromHashKey(streetHash))
            local crossing = crossingHash ~= 0 and cleanLabel(GetStreetNameFromHashKey(crossingHash)) or ''
            local zone = cleanLabel(GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z)))
            local showWaypoint = not RynHud.Theme.visibility or RynHud.Theme.visibility.waypoint ~= false
            local waypoint = showWaypoint and getWaypointData(coords, heading) or nil
            RynHud.PatchState({
                compass = {
                    heading = RynHud.Round(heading),
                    cardinal = headingLabel(heading),
                    street = street,
                    crossing = crossing,
                    zone = zone,
                    waypoint = waypoint,
                },
            })
        else
            wait = 800
        end
        Wait(wait)
    end
end)

CreateThread(function()
    while true do
        local wait = Config.IdentityTick or 1000
        if RynHud.Loaded then
            local holding = IsControlPressed(0, Config.PeekControl)
            local peekTheme = RynHud.Theme and RynHud.Theme.visibility
            local peekEnabled = not peekTheme or peekTheme.peekMoney ~= false
            local alwaysMoney = peekTheme and peekTheme.money == true
            local alwaysJob = peekTheme and peekTheme.job == true
            local peek = peekEnabled and (holding or GetGameTimer() < peekUntil)
            RynHud.Peeking = peek
            local identity = RynHud.GetBridge().getIdentity()
            RynHud.PatchState({
                identity = {
                    job = identity.job,
                    cash = identity.cash,
                    bank = identity.bank,
                    peek = peek,
                    showMoney = alwaysMoney or peek,
                    showJob = alwaysJob or peek,
                },
            })
            if holding then
                wait = 120
            end
        else
            wait = 500
        end
        Wait(wait)
    end
end)
