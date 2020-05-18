--- Neovim Qt 
--


local rpcnotify = vim.rpcnotify


local function channel()
    for i, chan in ipairs(vim.api.nvim_list_chans()) do
        local id = chan.id
        local client = chan.client
        if client ~= nil and client.name == "nvim-qt" and client.type == "ui" then
            return id
        end
    end
end


local function close()
    return rpcnotify(channel(), 'Gui', 'Close')
end


local function font(fontname, force)
    return rpcnotify(channel(), 'Gui', 'Font', fontname, force)
end


local function linespace(height)
    return rpcnotify(channel(), 'Gui', 'Linespace', height)
end


local function mousehide(enable)
    return rpcnotify(channel(), 'Gui', 'Mousehide', enable)
end


local function tabline(enable)
    return rpcnotify(channel(), 'Gui', 'Option', 'Tabline', enable)
end


local function popupmenu(enable)
    return rpcnotify(channel(), 'Gui', 'Option', 'Popupmen', enable)
end


local GUI_CLIPBOARD = string.gsub([[
let g:clipboard = {
  'name': 'custom',
  'copy': {
     '+': { lines, regtype -> rpcnotify(
                   g:nvim_qt_channel, 'Gui', 'SetClipboard',
		   lines, regtype, '+') },
     '*': { lines, regtype -> rpcnotify(
                   g:nvim_qt_channel, 'Gui', 'SetClipboard',
                   lines, regtype, '*') },
   },
  'paste': {
     '+': {-> rpcrequest(g:nvim_qt_channel, 'Gui', 'GetClipboard', '+')},
     '*': {-> rpcrequest(g:nvim_qt_channel, 'Gui', 'GetClipboard', '*')},
  },
}
]], "\n *", " ")


local function configure()
    vim.g.nvim_qt_channel = channel()
    vim.api.nvim_command(GUI_CLIPBOARD)
end


return {
    configure = configure,
    channel = channel,
    close = close,
    font = font,
    linespace = linespace,
    mousehide = mousehide,
    tabline = tabline,
    popupmenu = popupmenu
}


--- nvim_qt.lua ends here
