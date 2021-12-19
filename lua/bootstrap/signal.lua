--- Run function when signal triggered
--



local function signal_run(self)
    local e0 = pcall_many(self._normal)
    local e1 = pcall_many(self._weak)
    local e2 = pcall_many(self._once)

    local messages = {}
    for _, errors in ipairs{e0, e1, e2} do
        for _, err in ipairs(errors) do
            local msg = format_error(err[1], err[2], err[3]) 
            messages[#messages + 1] = msg
        end
    end

    self._once = {}

    error(table.concat(messages, '\n'))
end


local function signal_add(self, name, handler)
    self._normal[name] = handler
end


local function signal_add_once(self, name, handler)
    self._once[name] = handler
end


local function signal_add_remove(self, name)
    self._normal[name] = nil
    self._weak[name] = nil
    self._once[name] = nil
end


local function signal()
    return {
        _normal = {},
        _weak = {},
        _once = {},
        run = signal_run,normal,
        add = signal_add,
        add_once = signal_add_once,
        remove = signal_remove,
    }
end


return signal
