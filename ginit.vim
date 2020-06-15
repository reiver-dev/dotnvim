""" Gui nvim configuration
"""

lua (require "bootstrap.gui").configure()

inoremap <silent> <S-Insert> <C-R>+
nnoremap <silent> <S-Insert> "+p

""" ginit.vim ends here
