function L(key)
    local locales = rawget(_G, 'Locales') or {}
    local pack = locales[Config.Locale] or locales['en'] or {}
    return pack[key] or key
end
