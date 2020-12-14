""" Gui nvim configuration
"""

lua (require "bootstrap.gui").configure()

inoremap <silent> <S-Insert> <C-R>+
nnoremap <silent> <S-Insert> "+p
vnoremap <silent> <S-Insert> "+p

nnoremap <silent> <C-Insert> "+y
vnoremap <silent> <C-Insert> "+y

""" ginit.vim ends here
