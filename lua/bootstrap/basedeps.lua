--- Install basic dependencies

local function setup()
    local pack = require"bootstrap.pack"
    pack.add{
        {
            name = "fennel",
            src = "https://github.com/bakpakin/Fennel",
            data = {
                rtp = { "rtp" },
                module = { "fennel" },
                run = function()
                    vim.cmd("packadd fennel")
                    require "bootstrap.fennel.ensure_compiler".setup()
                end,
                opt = true,
            }
        },
    }
end


return { setup = setup }

--- basedeps.lua ends here
