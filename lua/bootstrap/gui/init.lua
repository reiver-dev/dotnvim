--- Gui client configuration
--


local function configure()
    local fvim = require "bootstrap.gui.fvim"
    local nvim_qt = require "bootstrap.gui.nvim_qt"

    if fvim.has() then
        fvim.configure()
    end

    local nvim_qt_chan = nvim_qt.channel()
    if nvim_qt_chan ~= nil then
	nvim_qt.configure()
    end
end


return {
    configure = configure,

}


--- gui/init.lua ends here
