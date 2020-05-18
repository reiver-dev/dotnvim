--- FVim
--


local function has()
    return vim.g.fvim_loaded
end


local function channel()
    return vim.g.fvim_channel
end


local function request(name, ...)
    return vim.rpcnotify(channel(), name, ...)
end


local function close()
    return request("remote.detach")
end


local function configure()
   request("cursor.smoothblink", true)
   request("cursor.smoothmove", true)
end


return {
    configure = configue,
    close = close,
    has = has,
}

--- fvim.lua ends here
