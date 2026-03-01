return function()
    local params = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
    local command = table.concat {
        "[Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new();",
        "$PSDefaultParameterValues['Out-File:Encoding']='utf8';",
        "$PSStyle.OutputRendering = 'PlainText';",
    }

    local opt = vim.opt
    opt.shelltemp = false
    opt.shell = 'pwsh'
    opt.shellcmdflag = params .. " " .. command
    opt.shellpipe = '> %s 2>&1'
    opt.shellquote=""
    opt.shellxquote=""
end
