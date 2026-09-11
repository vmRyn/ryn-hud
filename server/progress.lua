--- Server helpers for the progress bar (fire-and-forget).
--- For a boolean completion result, call Progress on the client instead.

local function progress(target, data, maybeDuration)
    if target == nil then
        return false
    end
    TriggerClientEvent('ryn-hud:client:progress', target, data, maybeDuration)
    return true
end

local function updateProgress(target, data)
    if target == nil then
        return false
    end
    TriggerClientEvent('ryn-hud:client:updateProgress', target, data)
    return true
end

local function cancelProgress(target)
    if target == nil then
        return false
    end
    TriggerClientEvent('ryn-hud:client:cancelProgress', target)
    return true
end

local function completeProgress(target)
    if target == nil then
        return false
    end
    TriggerClientEvent('ryn-hud:client:completeProgress', target)
    return true
end

exports('Progress', progress)
exports('ProgressBar', progress)
exports('progressBar', progress)
exports('StartProgress', progress)
exports('UpdateProgress', updateProgress)
exports('SetProgress', updateProgress)
exports('CancelProgress', cancelProgress)
exports('HideProgress', cancelProgress)
exports('CompleteProgress', completeProgress)
exports('FinishProgress', completeProgress)
