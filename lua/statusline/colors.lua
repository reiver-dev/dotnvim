-- Statusline colors

local base_colors_default = {
    bg_base = "#202328",
    fg_base = "#bbc2cf",
    yellow = "#ECBE7B",
    cyan = "#008080",
    darkblue = "#081633",
    green = "#98be65",
    orange = "#FF8800",
    violet = "#a9a1e1",
    magenta = "#c678dd",
    blue = "#51afef",
    red = "#ec5f67",
}


local base_colors_dark = {
    yellow = "Yellow",
    cyan = "DarkCyan",
    darkblue = "LightBlue",
    green = base_colors_default.green,
    orange = "Orange",
    violet = base_colors_default.violet,
    magenta = base_colors_default.magenta,
    blue = "LightBlue",
    red = base_colors_default.red,
}


local base_colors_light = {
    yellow = "Brown",
    cyan = "DarkCyan",
    darkblue = "DarkBlue",
    green = "DarkGreen",
    orange = "Brown",
    violet = "Purple",
    magenta = "DarkMagenta",
    blue = "SlateBlue",
    red = base_colors_default.red,
}


return {
    default = base_colors_default,
    dark = base_colors_dark,
    light = base_colors_light,
}
