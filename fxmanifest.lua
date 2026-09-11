fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ryn-hud'
author 'Ryn'
description 'Contextual high-quality HUD'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    'locales/en.lua',
    'shared/locale.lua',
    'shared/theme.lua',
}

client_scripts {
    'bridge/client.lua',
    'client/nui.lua',
    'client/main.lua',
    'client/status.lua',
    'client/vehicle.lua',
    'client/radar.lua',
    'client/contextual.lua',
    'client/extras.lua',
    'client/notifications.lua',
    'client/progress.lua',
    'client/seatswap.lua',
    'client/cinematic.lua',
    'client/visibility.lua',
    'client/admin.lua',
}

server_scripts {
    'bridge/server.lua',
    'server/permissions.lua',
    'server/theme.lua',
    'server/sync.lua',
    'server/notifications.lua',
    'server/progress.lua',
}

files {
    'html/index.html',
    'html/**/*',
    'data/theme.json',
}

-- Ensure after core, voice, and fuel on your server.cfg:
-- ensure qb-core / qbx_core / es_extended
-- ensure pma-voice
-- ensure ox_fuel (or LegacyFuel / cdn-fuel)
-- ensure jg-vehiclemileage  (optional; set Config.JGMileage = true)
-- ensure ryn-hud
