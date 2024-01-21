local visual_block = string.char(22) -- ^V
local select_block = string.char(19) -- ^S


local mode_groups = {
    normal = { "n", "niI", "niR", "niV" },
    normal_operator = { "no", "nov", "noV", "no" .. visual_block },
    normal_terminal = { "nt", "ntT" },
    visual = { "v", "V", visual_block },
    select = { "s", "S", select_block },
    insert = { "i", "ic", "ix" },
    command = { "c", "cv", "ce" },
    replace = { "R", "Rc", "Rv", "Rx"},
    visual_replace = { "Rvc", "Rvx" },
    prompt = { "r", "rm", "r?" },
    shell_pending = {"!"},
    terminal = { "t" },
}


local mode_symbols = {
    normal = {"Normal", "N"},
    normal_operator = {"Normal", "N"},
    normal_terminal = {"Normal", "N"},
    visual = {"Visual", "V"},
    insert = {"Insert", "I"},
    command = {"Command", "C"},
    prompt = {"Prompt", "P"},
    replace = {"Replace", "R"},
    visual_relace = {"Replace", "R"},
    select = {"Select", "S"},
    shell = {"Shell", "$"},
    terminal = {"Terminal", "T"},
}


local mode_symbols_mapping = {}
do
    for group, modes in pairs(mode_groups) do
        local symbol = mode_symbols[group]
        for i = 1,#modes do
            mode_symbols_mapping[modes[i]] = symbol
        end
    end
end


return {
    select_block = select_block,
    visual_block = visual_block,
    groups = mode_groups,
    symbols = mode_symbols,
    mode_to_symbol = mode_symbols_mapping,
}
