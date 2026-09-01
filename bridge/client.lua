RynHud = RynHud or {}
RynHud.Bridge = RynHud.Bridge or {}

local FRAMEWORK_RESOURCES = {
    qbx_core = true,
    ['qb-core'] = true,
    es_extended = true,
}

local detected = nil
local qbCore = nil
local esx = nil

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

local function getQbxPlayer()
    local player = rawget(_G, 'QBX') and QBX.PlayerData or nil
    if player then
        return player
    end
    local ok, data = pcall(function()
        return exports.qbx_core:GetPlayerData()
    end)
    if ok then
        return data
    end
    return nil
end

local adapters = {}

adapters.standalone = {
    name = 'standalone',
    onPlayerLoaded = function(cb)
        CreateThread(function()
            while not NetworkIsPlayerActive(PlayerId()) do
                Wait(200)
            end
            cb()
        end)
    end,
    getNeeds = function()
        return { hunger = 100, thirst = 100, stress = nil }
    end,
    getIdentity = function()
        return { job = '', cash = 0, bank = 0 }
    end,
}

adapters.qb = {
    name = 'qb',
    onPlayerLoaded = function(cb)
        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', cb)
        CreateThread(function()
            local core = getQBCore()
            if not core then
                return
            end
            local data = core.Functions.GetPlayerData()
            if data and data.citizenid then
                cb()
            end
        end)
    end,
    getNeeds = function()
        local core = getQBCore()
        if not core then
            return adapters.standalone.getNeeds()
        end
        local data = core.Functions.GetPlayerData() or {}
        local meta = data.metadata or {}
        return {
            hunger = meta.hunger,
            thirst = meta.thirst,
            stress = meta.stress,
        }
    end,
    getIdentity = function()
        local core = getQBCore()
        if not core then
            return adapters.standalone.getIdentity()
        end
        local data = core.Functions.GetPlayerData() or {}
        local job = data.job or {}
        local money = data.money or {}
        return {
            job = job.label or job.name or '',
            cash = money.cash or 0,
            bank = money.bank or 0,
        }
    end,
}

adapters.qbx = {
    name = 'qbx',
    onPlayerLoaded = function(cb)
        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', cb)
        RegisterNetEvent('qbx_core:client:playerLoaded', cb)
        CreateThread(function()
            if LocalPlayer.state.isLoggedIn then
                cb()
            end
        end)
    end,
    getNeeds = function()
        local player = getQbxPlayer()
        if not player then
            return adapters.qb.getNeeds()
        end
        local meta = player.metadata or {}
        return {
            hunger = meta.hunger,
            thirst = meta.thirst,
            stress = meta.stress,
        }
    end,
    getIdentity = function()
        local player = getQbxPlayer()
        if not player then
            return adapters.qb.getIdentity()
        end
        local job = player.job or {}
        local money = player.money or {}
        return {
            job = job.label or job.name or '',
            cash = money.cash or 0,
            bank = money.bank or 0,
        }
    end,
}

local esxNeeds = { hunger = 100, thirst = 100, stress = nil }

RegisterNetEvent('esx_status:onTick', function(data)
    if type(data) ~= 'table' then
        return
    end
    for _, entry in pairs(data) do
        if type(entry) == 'table' and entry.name == 'hunger' then
            esxNeeds.hunger = entry.percent or (entry.val and entry.val / 10000) or esxNeeds.hunger
        elseif type(entry) == 'table' and entry.name == 'thirst' then
            esxNeeds.thirst = entry.percent or (entry.val and entry.val / 10000) or esxNeeds.thirst
        elseif type(entry) == 'table' and entry.name == 'stress' then
            esxNeeds.stress = entry.percent or esxNeeds.stress
        end
    end
end)

adapters.esx = {
    name = 'esx',
    onPlayerLoaded = function(cb)
        RegisterNetEvent('esx:playerLoaded', function()
            cb()
        end)
        CreateThread(function()
            local ESX = getESX()
            if ESX and ESX.PlayerLoaded then
                cb()
            end
        end)
    end,
    getNeeds = function()
        return {
            hunger = esxNeeds.hunger,
            thirst = esxNeeds.thirst,
            stress = esxNeeds.stress,
        }
    end,
    getIdentity = function()
        local ESX = getESX()
        if not ESX then
            return adapters.standalone.getIdentity()
        end
        local data = ESX.GetPlayerData and ESX.GetPlayerData() or {}
        local job = data.job or {}
        local cash, bank = 0, 0
        if type(data.accounts) == 'table' then
            for i = 1, #data.accounts do
                local acc = data.accounts[i]
                if acc and (acc.name == 'money' or acc.name == 'cash') then
                    cash = acc.money or 0
                elseif acc and acc.name == 'bank' then
                    bank = acc.money or 0
                end
            end
        end
        return {
            job = job.label or job.name or '',
            cash = cash,
            bank = bank,
        }
    end,
}

function RynHud.GetFramework()
    if not detected then
        detected = detectFramework()
    end
    return detected
end

function RynHud.GetBridge()
    local name = RynHud.GetFramework()
    return adapters[name] or adapters.standalone
end

AddEventHandler('onResourceStart', function(resource)
    if FRAMEWORK_RESOURCES[resource] then
        detected = nil
        qbCore = nil
        esx = nil
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if FRAMEWORK_RESOURCES[resource] then
        detected = nil
        qbCore = nil
        esx = nil
    end
end)

RynHud.Bridge = setmetatable({}, {
    __index = function(_, key)
        local adapter = RynHud.GetBridge()
        return adapter[key]
    end,
})
