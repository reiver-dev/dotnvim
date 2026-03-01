local function setup()
    local OS = vim.loop.os_uname()
    local iswin = OS.sysname:match("^Windows")
    if iswin then
        if vim.fn.executable("pwsh") then
            require "bootstrap.shell.pwsh"()
        end
    end
end

return {
    setup = setup,
}
