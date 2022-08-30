(fn buffers [opts]
  (let [builtin (require :telescope.builtin)
        themes (require :telescope.themes)]
    (builtin.buffers (themes.get_ivy {:previewer false
                                      :results_title false}))))


(fn history [opts]
  (let [builtin (require :telescope.builtin)
        themes (require :telescope.themes)]
    (builtin.oldfiles (themes.get_ivy {:previewer false
                                       :only_cwd (and opts opts.bang)
                                       :results_title false}))))


(fn ripgrep [opts]
  (local builtin (require :telescope.builtin))
  (local topts {:search opts.args
                :additional_args (when (= opts.bang "!") #["--no-ignore"])})
  (builtin.grep_string topts))


(fn get-telescope []
  {:finders (require "telescope.finders")
   :pickers (require "telescope.pickers")
   :entry (require "telescope.make_entry")
   :previewers (require "telescope.previewers")
   :config (. (require "telescope.config") :values)
   :sorters (require "telescope.sorters")})


(fn grep [opts]
  (local t (get-telescope))
  (local search opts.args)
  (local args ["grep" "-E" search "-Hn" "-r" "*"])
  (local topts {:entry_maker (t.entry.gen_from_vimgrep {:__inverted true})})
  (->
    {:prompt_title (string.format "Grep (%s)" search)
     :finder (t.finders.new_oneshot_job args topts)
     :previewer (t.config.grep_previewer topts)
     :sorter (t.config.generic_sorter topts)}
    (t.pickers.new)
    (: :find)))


(fn files [opts]
  (local builtin (require :telescope.builtin))
  (local topts {:search_file opts.args
                :hidden opts.bang
                :no_ignore opts.bang})
  (builtin.find_files topts))


(fn setup []
  (vim.api.nvim_set_keymap :n "<C-x>b" "" {:noremap true :callback buffers})
  (vim.api.nvim_set_keymap :n "<C-x>r" "" {:noremap true :callback history})
  (vim.api.nvim_create_user_command :History history {:bang true})
  (vim.api.nvim_create_user_command :Buffers buffers {})
  (vim.api.nvim_create_user_command :Rg ripgrep {:nargs "?" :bang true})
  (vim.api.nvim_create_user_command :Grep grep {:nargs "?"})
  (vim.api.nvim_create_user_command :Files files {:nargs "?" :bang true}))


{: setup}
