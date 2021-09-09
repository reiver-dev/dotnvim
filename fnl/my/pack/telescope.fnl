(module my.pack.telescope)

(defn configure []
  (local telescope (require :telescope))
  (local actions (require :telescope.actions))
  (local border ["─" "│" "─" "│" "┌" "┐" "┘" "└"])
  (telescope.setup
    {:defaults
     {:mappings
      {:n {:<C-g> actions.close
           :<C-n> actions.move_selection_next
           :<C-p> actions.move_selection_previous
           :q actions.close}
       :i {:<C-g> actions.close
           :<C-c> actions.close}}
      :prompt_prefix "❯ "
      :selection_caret " "
      :layout_config {:prompt_position :top}
      :borderchars border}})
  (vim.cmd "highlight TelescopeBorder guifg=Grey37")
  (_T :telescope :load_extension :my))


(defn buffers []
  (let [builtin (require :telescope.builtin)
        themes (require :telescope.themes)]
    (builtin.buffers (themes.get_ivy {:previewer false}))))


(defn find-file []
  (let [builtin (require :telescope.builtin)
        themes (require :telescope.themes)]
    (builtin.file_browser (themes.get_ivy {:previewer false}))))


(defn setup []
  (configure)
  (vim.api.nvim_set_keymap
    :n "<C-x>f" "<cmd>lua _T('my.pack.telescope', 'find-file')<CR>" {:noremap true})
  (vim.api.nvim_set_keymap
    :n "<C-x>b" "<cmd>lua _T('my.pack.telescope', 'buffers')<CR>" {:noremap true}))
