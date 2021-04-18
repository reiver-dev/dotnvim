(module my.pack.telescope)

(defn configure []
  (_T :telescope :setup
      {:defaults
       {:prompt_prefix "❯ "
        :selection_caret "❯ "
        :prompt_position :top
        :borderchars ["─" "│" "─" "│" "┌" "┐" "┘" "└"]}}))

(defn setup []
  (configure)
  (_T :telescope :load_extension :my)
  (vim.api.nvim_set_keymap
    :n "<C-x>b" "<cmd>Telescope buffers<CR>" {:noremap true}))
