do
    local sep = package.config:sub(1, 1)
    local path = vim.fn.stdpath("data") .. sep .. "packer_compiled.lua"
    local packer_compiled, err = loadfile(path)
    if packer_compiled then
        packer_compiled()
        -- pull preload and fennel loaders before
        -- packer's lazy loader
        local loaders = package.loaders
        local lazy_loader = loaders[1]
        loaders[1] = loaders[2]
        loaders[2] = loaders[3]
        loaders[3] = lazy_loader
    elseif err and not err:match("No such file or directory$") then
        error(err)
    end
end
