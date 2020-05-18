""" Install luafun library

let s:url = 'https://raw.githubusercontent.com/luafun/luafun/master/fun.lua'
let s:root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
let s:dest = s:root .. "/lua/fun.lua"
let s:cmd = "!curl -L " . s:url . " -o " . s:dest . " --create-dirs"

if !filereadable(s:dest)
    echo "Calling: " .. s:cmd
    execute s:cmd
endif

lua <<EOF
for k, v in pairs(require("fun")) do
    rawset(_G, k, v)
end
EOF

""" luafun.vim ends here
