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
    if type(job.onFinish) == 'function' then
        job.onFinish(success == true)
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
        value = data.value or data.percent or data.progress
        label = sanitizeLabel(data.label or data.name or data.text)
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

local function normalizeOpts(data, maybeDuration)
    local opts = {}
    if type(data) == 'string' then
        opts.label = data
        if type(maybeDuration) == 'number' then
            opts.duration = maybeDuration
        elseif type(maybeDuration) == 'table' then
            for k, v in pairs(maybeDuration) do
                opts[k] = v
            end
            opts.label = data
        end
    elseif type(data) == 'table' then
        opts = data
    else
        return nil
    end
    return opts
end

--- Start a progress bar.
--- Timed (blocks until done): Progress({ label = 'Lockpicking', duration = 5000, canCancel = true }) → boolean
--- Timed shorthand:          Progress('Lockpicking', 5000)
--- Manual:                   Progress({ label = 'Upload', value = 0 }) → true; then UpdateProgress
--- Callback:                 Progress({ ..., onFinish = function(ok) end })
---@return boolean
local function startProgress(data, maybeDuration)
    if not enabled() then
        return false
    end
    if active then
        return false
    end

    local opts = normalizeOpts(data, maybeDuration)
    if not opts then
        return false
    end

    local label = sanitizeLabel(opts.label or opts.name or opts.text or opts.description) or 'Please wait…'
    local duration = tonumber(opts.duration) or tonumber(opts.time) or tonumber(opts.ms)
    if duration then
        duration = math.floor(RynHud.Clamp(duration, 200, 120000))
    end
    local value = tonumber(opts.value) or tonumber(opts.percent) or tonumber(opts.progress)
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
    local canCancel = opts.canCancel == true or opts.cancel == true
    local disable = opts.disable
    if disable == nil then
        disable = true
    end
    local onFinish = opts.onFinish or opts.onComplete or opts.cb
    if type(onFinish) ~= 'function' then
        onFinish = nil
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
        onFinish = onFinish,
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

--- Non-blocking progress. Returns immediately; use onFinish / the returned handle.
--- StartProgress({ label = 'Hack', duration = 4000, onFinish = function(ok) end })
---@return boolean started
local function startProgressAsync(data, maybeDuration)
    if not enabled() then
        return false
    end
    if active then
        return false
    end

    local opts = normalizeOpts(data, maybeDuration)
    if not opts then
        return false
    end

    CreateThread(function()
        startProgress(opts)
    end)
    return true
end

local function isProgressActive()
    return active ~= nil
end

local function isProgressEnabled()
    return enabled()
end

local function completeProgress()
    if not active then
        return false
    end
    resolve(true)
    return true
end

local function getProgress()
    if not active then
        return nil
    end
    return {
        id = active.id,
        label = active.label,
        value = active.value,
        duration = active.duration,
        canCancel = active.canCancel == true,
    }
end

RynHud.Progress = startProgress
RynHud.StartProgress = startProgressAsync
RynHud.UpdateProgress = updateProgress
RynHud.CancelProgress = cancelProgress
RynHud.HideProgress = hideProgress
RynHud.CompleteProgress = completeProgress
RynHud.IsProgressActive = isProgressActive
RynHud.IsProgressEnabled = isProgressEnabled

exports('Progress', startProgress)
exports('ProgressBar', startProgress)
exports('progressBar', startProgress)
exports('StartProgress', startProgressAsync)
exports('UpdateProgress', updateProgress)
exports('SetProgress', updateProgress)
exports('CancelProgress', cancelProgress)
exports('HideProgress', hideProgress)
exports('CompleteProgress', completeProgress)
exports('FinishProgress', completeProgress)
exports('IsProgressActive', isProgressActive)
exports('IsProgressEnabled', isProgressEnabled)
exports('GetProgress', getProgress)

RegisterNetEvent('ryn-hud:client:progress', function(data, maybeDuration)
    CreateThread(function()
        startProgress(data, maybeDuration)
    end)
end)

RegisterNetEvent('ryn-hud:client:updateProgress', function(data)
    updateProgress(data)
end)

RegisterNetEvent('ryn-hud:client:cancelProgress', function()
    cancelProgress()
end)

RegisterNetEvent('ryn-hud:client:completeProgress', function()
    completeProgress()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and active then
        active = nil
        RynHud.SendNui('progressHide')
    end
end)
