local function needValue(value, fallback)
    if value == nil then
        return fallback
    end
    return RynHud.Round(RynHud.Clamp(value, 0, 100))
end

local function displayHealth(ped)
    local base = tonumber(Config.BaseMaxHealth) or 100
    if base <= 0 then
        base = 100
    end
    local cap = tonumber(Config.MaxDisplayHealth) or 150
    if cap < base then
        cap = base
    end

    -- Absolute HP vs fixed base (not current max), so raised max/overheal reads >100.
    local raw = GetEntityHealth(ped) - 100
    if raw < 0 then
        raw = 0
    end
    return RynHud.Round(RynHud.Clamp((raw / base) * 100, 0, cap))
end

CreateThread(function()
    while true do
        local wait = Config.StatusTick or 200
        if RynHud.Loaded then
            local ped = PlayerPedId()
            local needs = RynHud.GetBridge().getNeeds()
            RynHud.PatchState({
                health = displayHealth(ped),
                armor = RynHud.Round(RynHud.Clamp(GetPedArmour(ped), 0, 100)),
                hunger = needValue(needs.hunger, 100),
                thirst = needValue(needs.thirst, 100),
                stress = needs.stress ~= nil and RynHud.Round(RynHud.Clamp(needs.stress, 0, 100)) or nil,
            })
        else
            wait = 500
        end
        Wait(wait)
    end
end)
