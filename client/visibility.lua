RynHud.HudVisible = true
RynHud.Obscured = false

local function shouldObscure()
    return IsPauseMenuActive() or IsScreenFadedOut()
end

function RynHud.SetHudVisible(show)
    show = show ~= false
    if RynHud.HudVisible == show then
        return show
    end

    RynHud.HudVisible = show
    if not RynHud.Obscured then
        RynHud.SendNui('setHudVisible', { visible = show })
    end

    if not show then
        DisplayRadar(false)
    end

    return show
end

CreateThread(function()
    while true do
        local hide = shouldObscure()
        if hide ~= RynHud.Obscured then
            RynHud.Obscured = hide
            if not RynHud.AdminOpen then
                if hide then
                    RynHud.SendNui('setHudVisible', { visible = false })
                else
                    RynHud.SendNui('setHudVisible', { visible = RynHud.HudVisible ~= false })
                end
            end
        end
        Wait(hide and 200 or 400)
    end
end)

exports('SetHudVisible', RynHud.SetHudVisible)
exports('IsHudVisible', function()
    return RynHud.HudVisible == true
end)
