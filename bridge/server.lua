RynHud = RynHud or {}

local FRAMEWORK_RESOURCES = {
    qbx_core = true,
    ['qb-core'] = true,
    es_extended = true,
}

local function resourceStarted(name)
    return GetResourceState(name) == 'started'
end

local function detectFramework()
    if Config.Framework ~= 'auto' then
        return Config.Framework
    end
    if resourceStarted('qbx_core') then
        return 'qbx'
    end
    if resourceStarted('qb-core') then
        return 'qb'
    end
    if resourceStarted('es_extended') then
        return 'esx'
    end
    return 'standalone'
end

local framework = detectFramework()
local qbCore = nil
local esx = nil

local function getQBCore()
    if qbCore then
        return qbCore
    end
    if not resourceStarted('qb-core') then
        return nil
    end
    local ok, core = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    if ok and core then
        qbCore = core
        return qbCore
    end
    return nil
end

local function getESX()
    if esx then
        return esx
    end
    if not resourceStarted('es_extended') then
        return nil
    end
    local ok, obj = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)
    if ok and obj then
        esx = obj
        return esx
    end
    return nil
end

AddEventHandler('onResourceStart', function(resource)
    if FRAMEWORK_RESOURCES[resource] then
        framework = detectFramework()
        qbCore = nil
        esx = nil
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if FRAMEWORK_RESOURCES[resource] then
        qbCore = nil
        esx = nil
        framework = detectFramework()
    end
end)

local function hasConfiguredGroup(group)
    if not group then
        return false
    end
    return Config.AdminGroups[group] == true
end

function RynHud.IsAdmin(src)
    if type(src) ~= 'number' or src <= 0 then
        return false
    end
    if IsPlayerAceAllowed(src, Config.AdminAce) then
        return true
    end

    if framework == 'qbx' and resourceStarted('qbx_core') then
        for group in pairs(Config.AdminGroups) do
            local ok, allowed = pcall(function()
                return exports.qbx_core:HasPermission(src, group)
            end)
            if ok and allowed then
                return true
            end
        end
    end

    if (framework == 'qb' or framework == 'qbx') and resourceStarted('qb-core') then
        local core = getQBCore()
        if core then
            if core.Functions.HasPermission then
                for group in pairs(Config.AdminGroups) do
                    if core.Functions.HasPermission(src, group) then
                        return true
                    end
                end
            end
            local player = core.Functions.GetPlayer(src)
            if player and player.PlayerData and hasConfiguredGroup(player.PlayerData.group) then
                return true
            end
        end
    end

    if framework == 'esx' and resourceStarted('es_extended') then
        local ESX = getESX()
        if ESX then
            local player = ESX.GetPlayerFromId(src)
            if player then
                local group = player.getGroup and player.getGroup() or player.group
                if hasConfiguredGroup(group) then
                    return true
                end
            end
        end
    end

    return false
end
