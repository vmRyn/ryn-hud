local active = nil

local function cfg()
    local c = Config.Progress
    if type(c) ~= 'table' then
        return {
            enabled = c ~= false,
            cancelControl = 73,
        }
    end
    return c
end

local function enabled()
    return cfg().enabled ~= false
end

local function resolve(success)
    if not active then
        return
    end
    local job = active
    active = nil
    RynHud.SendNui('progressHide')
    if job.promise then
        job.promise:resolve(success == true)
    end
end

local function hideProgress()
    if not active then
        RynHud.SendNui('progressHide')
        return false
    end
    resolve(false)
    return true
end

local function cancelProgress()
    if not active then
        return false
    end
    resolve(false)
    return true
end

local function sanitizeLabel(value)
    if type(value) ~= 'string' then
        return nil
    end
    value = value:gsub('%s+', ' '):match('^%s*(.-)%s*$') or ''
    if value == '' then
        return nil
    end
    if #value > 64 then
        value = value:sub(1, 64)
    end
    return value
end

local function pushProgress(payload)
    RynHud.SendNui('progressShow', payload)
end

local function updateProgress(data)
    if not active then
        return false
    end
    local value = data
    local label = nil
    if type(data) == 'table' then
        value = data.value
        label = sanitizeLabel(data.label or data.name)
    end
    value = RynHud.Clamp(tonumber(value) or 0, 0, 100)
    if label then
        active.label = label
    end
    active.value = value
    RynHud.SendNui('progressUpdate', {
        id = active.id,
        value = value,
        label = active.label,
    })
    if value >= 100 and not active.duration then
        resolve(true)
    end
    return true
end

--- Start a progress bar.
--- Timed:   Progress({ label = 'Lockpicking', duration = 5000, canCancel = true }) → waits, returns bool
--- Manual:  Progress({ label = 'Upload', value = 0 }) → returns true immediately; use UpdateProgress
---@param data table|string
---@param maybeDuration number|nil
---@return boolean
local function startProgress(data, maybeDuration)
    if not enabled() then
        return false
    end
    if active then
        return false
    end

    local opts = {}
    if type(data) == 'string' then
        opts.label = data
        opts.duration = maybeDuration
    elseif type(data) == 'table' then
        opts = data
    else
        return false
    end

    local label = sanitizeLabel(opts.label or opts.name or opts.text) or 'Please wait…'
    local duration = tonumber(opts.duration)
    if duration then
        duration = math.floor(RynHud.Clamp(duration, 200, 120000))
    end
    local value = tonumber(opts.value)
    if value then
        value = RynHud.Clamp(value, 0, 100)
    elseif not duration then
        value = 0
    end

    local icon = opts.icon
    if icon and not (RynHud.IsAllowedIcon and RynHud.IsAllowedIcon(icon)) then
        icon = nil
    end
    local color = RynHud.SanitizeColor and RynHud.SanitizeColor(opts.color, nil) or nil
    local canCancel = opts.canCancel == true
    local disable = opts.disable
    if disable == nil then
        disable = true
    end

    local id = ('p-%d'):format(GetGameTimer())
    local p = duration and promise.new() or nil

    active = {
        id = id,
        label = label,
        duration = duration,
        value = value or 0,
        canCancel = canCancel,
        disable = disable,
        promise = p,
    }

    pushProgress({
        id = id,
        label = label,
        duration = duration,
        value = value,
        icon = icon,
        color = color,
        canCancel = canCancel,
    })

    if not duration then
        return true
    end

    local cancelControl = tonumber(cfg().cancelControl) or 73
    local endsAt = GetGameTimer() + duration

    while active and active.id == id and GetGameTimer() < endsAt do
        if active.disable then
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 75, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 263, true)
            DisablePlayerFiring(PlayerId(), true)
        end

        if active.canCancel and (IsControlJustPressed(0, cancelControl) or IsDisabledControlJustPressed(0, cancelControl)) then
            resolve(false)
            break
        end

        Wait(0)
    end

    if active and active.id == id then
        resolve(true)
    end

    local result = Citizen.Await(p)
    return result == true
end

local function isProgressActive()
    return active ~= nil
end

local function completeProgress()
    if not active then
        return false
    end
    resolve(true)
    return true
end

RynHud.Progress = startProgress
RynHud.UpdateProgress = updateProgress
RynHud.CancelProgress = cancelProgress
RynHud.HideProgress = hideProgress
RynHud.CompleteProgress = completeProgress
RynHud.IsProgressActive = isProgressActive

exports('Progress', startProgress)
exports('UpdateProgress', updateProgress)
exports('CancelProgress', cancelProgress)
exports('HideProgress', hideProgress)
exports('CompleteProgress', completeProgress)
exports('IsProgressActive', isProgressActive)

RegisterNetEvent('ryn-hud:client:progress', function(data, maybeDuration)
    startProgress(data, maybeDuration)
end)

RegisterNetEvent('ryn-hud:client:updateProgress', function(data)
    updateProgress(data)
end)

RegisterNetEvent('ryn-hud:client:cancelProgress', function()
    cancelProgress()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and active then
        active = nil
        RynHud.SendNui('progressHide')
    end
end)
