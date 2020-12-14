""" Install luafun library

let s:url = 'https://raw.githubusercontent.com/luafun/luafun/master/fun.lua'
let s:root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
let s:dest = s:root .. "/lua/fun.lua"
let s:cmd = "!curl -L " . s:url . " -o " . s:dest . " --create-dirs"

if !filereadable(s:dest)
    echo "Calling: " .. s:cmd
    execute s:cmd
endif

lua fun = require("fun")

lua <<EOF
for k, v in pairs(fun) do
    rawset(_G, "f-" .. k:gsub('_', '-'), v)
end
EOF

""" luafun.vim ends here
