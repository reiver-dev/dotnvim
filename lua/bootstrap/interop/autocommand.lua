--- Autocommands
--


local function autocmd(opts)
    local event = opts.event
    local pat = opts.pat
    local cmd = opts.cmd
    local group = opts.group

    local once = opts.once ~= nil
    local nested = opts.nested ~= nil

    vim.validate {
    	event = {event, 's'},
	pat = {pat, 's'},
	cmd = {cmd, 's'},
	group = {group, 's', true},
    }


    local result = { "autocmd" }
    local pos = 2
    local add = function (value)
        if value ~= nil then
            result[pos] = value
            pos = pos + 1
        end
    end

    if group ~= nil and #group > 0 then
        add(group)
    end
    
    if event ~= nil and #event > 0 then
        add(event)
    end

    if pat ~= nil then
	if type(pat) == "string" then
            add(pat)
	elseif type(pat) == "table" then
	    add(table.concat(pat, ","))
	else
	    error(string.format(
	        "Invalid pattern value: [%s] %s",
	         type(pat), pat
	    ))
	end
    else
        add("*")
    end

    if once then
        add("++once")
    end

    if nested then
        add("++nested")
    end

    add(cmd)

    return table.concat(result, ' ')
end


local function augroup(definitions)
    for name, definition in pairs(definitions) do
        vim.api.nvim_command('augroup ' .. name)
        vim.api.nvim_command('autocmd!')
        for _, def in ipairs(definition) do
            vim.api.nvim_command(autocmd(def))
        end
        vim.api.nvim_command('augroup END')
    end
end


return {
    augroup = augroup,
    autocmd = autocmd
}


--- autocommand.lua ends here
