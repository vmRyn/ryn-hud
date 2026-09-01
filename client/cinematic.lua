RynHud.Cinematic = false

function RynHud.SetCinematic(active, silent)
    active = active and true or false
    if RynHud.Cinematic == active then
        return active
    end

    RynHud.Cinematic = active
    RynHud.SendNui('setCinematic', {
        active = active,
        barHeight = Config.CinematicBarHeight or 11,
    })

    if active then
        DisplayRadar(false)
        if not silent then
            RynHud.Notify('cinematic_on')
        end
    elseif not silent then
        RynHud.Notify('cinematic_off')
    end

    return active
end

function RynHud.ToggleCinematic()
    return RynHud.SetCinematic(not RynHud.Cinematic)
end

RegisterCommand(Config.CinematicCommand, function()
    RynHud.ToggleCinematic()
end, false)

exports('SetCinematic', RynHud.SetCinematic)
exports('ToggleCinematic', RynHud.ToggleCinematic)
exports('IsCinematic', function()
    return RynHud.Cinematic == true
end)
