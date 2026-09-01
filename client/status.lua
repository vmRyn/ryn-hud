CreateThread(function()
    while true do
        local wait = Config.StatusTick or 200
        if RynHud.Loaded then
            local ped = PlayerPedId()
            local health = GetEntityHealth(ped) - 100
            if health < 0 then
                health = 0
            end
            local maxHealth = GetEntityMaxHealth(ped) - 100
            if maxHealth <= 0 then
                maxHealth = 100
            end
            local needs = RynHud.GetBridge().getNeeds()
            RynHud.PatchState({
                health = RynHud.Round(RynHud.Clamp((health / maxHealth) * 100, 0, 100)),
                armor = RynHud.Round(RynHud.Clamp(GetPedArmour(ped), 0, 100)),
                hunger = RynHud.Round(RynHud.Clamp(needs.hunger, 0, 100)),
                thirst = RynHud.Round(RynHud.Clamp(needs.thirst, 0, 100)),
                stress = needs.stress ~= nil and RynHud.Round(RynHud.Clamp(needs.stress, 0, 100)) or nil,
            })
        else
            wait = 500
        end
        Wait(wait)
    end
end)
