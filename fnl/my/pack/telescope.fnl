(module my.pack.telescope)

(defn configure []
  (_T :telescope :setup
      {:defaults
       {:prompt_prefix "❯ "
        :selection_caret "❯ "
        :layout_config {:prompt_position :top}
        :borderchars ["─" "│" "─" "│" "┌" "┐" "┘" "└"]}}))

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
  (_T :telescope :load_extension :my)
  (vim.api.nvim_set_keymap
    :n "<C-x>f" "<cmd>lua _T('my.pack.telescope', 'find-file')<CR>" {:noremap true})
  (vim.api.nvim_set_keymap
    :n "<C-x>b" "<cmd>lua _T('my.pack.telescope', 'buffers')<CR>" {:noremap true}))
