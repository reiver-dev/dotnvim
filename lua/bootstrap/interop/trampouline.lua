--- VimL to lua call helper
--

local NAME = "v:lua._trampouline(%q, %q, %s)"

local ARGS_COMMAND = string.gsub([[{
  'args': [<f-args>],
  'first': <line1>,
  'last': <line2>,
  'range': <range>,
  'count': <count>,
  'bang': '<bang>',
  'mods': '<mods>',
  'reg': '<reg>',
  'rawargs': <q-args>
}]], "\n *", " ")

local ARGS_AUTOCMD = string.gsub([[{
  'buf': expand('<abuf>'),
  'match': expand('<amatch>'),
  'file': expand('<afile>')
}]], "\n *", " ")


local function make_command(modname, funcname)
    return string.format(NAME, modname, funcname, ARGS_COMMAND)
end

local function make_autocommand(modname, funcname)
    return string.format(NAME, modname, funcname, ARGS_AUTOCMD)
end


return {
    command = make_command,
    autocmd = make_autocommand
}

--- trampouline.lua ends here
