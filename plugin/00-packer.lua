do
    local sep = package.config:sub(1, 1)
    local path = vim.fn.stdpath("data") .. sep .. "packer_compiled.lua"
    local mod, err = loadfile(path)
    if mod then
        mod()
    elseif not err:match("No such file or directory$") then
        error(err)
    end
end
