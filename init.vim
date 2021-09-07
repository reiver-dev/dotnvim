""" Main nvim config
"""

lua <<EOL
    local mod = require("bootstrap")
    mod.setup()
    mod.setup_after()
EOL


""" init.vim ends here
