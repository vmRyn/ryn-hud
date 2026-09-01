-- Permissions live on the server bridge. This file keeps a stable export.
exports('IsAdmin', function(src)
    return RynHud.IsAdmin(src)
end)
