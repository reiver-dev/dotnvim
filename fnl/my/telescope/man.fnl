(module my.telescope.man
  {require {t-entry telescope.make_entry
            t-edisplay telescope.pickers.entry_display
            t-finders telescope.finders
            t-pickers telescope.pickers
            t-sorters telescope.sorters
            t-previewers telescope.previewers
            t-actions telescope.actions
            t-utils telescope.utils
            t-putils telescope.previewers.utils}})


(defn- find-man-pages-cmd [opts]
  (let [result ["apropos"]]
    (table.insert result (.. "--section=" (or opts.man_section "1")))
    (when opts.man_path
      (table.insert result (.. "--manpath=" opts.man_path)))
    (table.insert result (or opts.man_pattern ""))
    result))
      


(defn- entry-parse [text]
  (let [(name section) (string.match text "(.*)%((.*)%)")]
    (if name
      (values name section)
      text)))


(defn- erzatz-man-filetype [bufnr section]
  (when (let [(ok res) (pcall (fn [] (vim.api.nvim_buf_get_var
                                       bufnr :did_ftplugin)))]
          (or (not ok) (~= res 1)))
    (vim.api.nvim_buf_set_var bufnr :did_ftplugin 1)
    (vim.api.nvim_buf_set_var bufnr :man_sect (or section ""))
    (vim.api.nvim_buf_set_option bufnr :filetype "man")
    (vim.api.nvim_buf_set_option bufnr :iskeyword
                                 "@-@,:,a-z,A-Z,48-57,_,.,-,(,)")))


(defn- man-buffer-highlight [bufnr]
  (let [hl (.  (require "man") :highlight_man_page)]
    (vim.api.nvim_buf_call bufnr hl)))
  

(defn- process-environment [tbl]
  (when tbl
    (let [base (vim.fn.environ)]
      (each [k v (pairs tbl)]
        (tset base k v))
      base)))

  
(def- man-previewer
  (t-utils.make_default_callable
    (fn [_]
      (t-previewers.new_buffer_previewer
        {:get_buffer_by_name (fn [_ entry] 
                               (let [name (entry-parse entry.value)]
                                 name))
         :define_preview
         (fn [self entry status]
           (let [(name section) (entry-parse entry.value)
                 command (let [command ["man"]]
                           (when section
                             (table.insert command section))
                           (table.insert command name)
                           command)
                 env (process-environment
                       {"MANPAGER" "cat"
                        "MAN_KEEP_FORMATTING" "1"
                        "MANWIDTH" (vim.api.nvim_win_get_width
                                     self.state.winid)})]
             ;; Run man
             (t-putils.job_maker command self.state.bufnr
                                 {:env env
                                  :callback (fn [bufnr]
                                              (man-buffer-highlight bufnr)
                                              (erzatz-man-filetype bufnr section))
                                  :value entry.value
                                  :bufname self.state.bufname})))}))))


(defn- call-selection-command [command]
  (fn [bufnr]
    (let [selection (t-actions.get_selected_entry)]
      (t-actions.close bufnr)
      (vim.cmd (command:format selection.value)))))


(def- man-edit (call-selection-command "Man %s"))
(def- man-hsplit (call-selection-command "Man %s"))
(def- man-vsplit (call-selection-command "vert bo Man %s"))
(def- man-tabedit (call-selection-command "tab Man %s"))


(defn- action-mapper [bufnr]
  (t-actions.goto_file_selection_edit:replace man-edit)
  (t-actions.goto_file_selection_split:replace man-hsplit)
  (t-actions.goto_file_selection_vsplit:replace man-vsplit)
  (t-actions.goto_file_selection_tabedit:replace man-tabedit)
  true)
                                      

(defn manpages [opts]
  (let [opts (or opts {})
        section (or opts.man_section "1")
        entries (t-utils.get_os_command_output (find-man-pages-cmd opts))
        picker (t-pickers.new
                 opts
                 {:prompt_title (string.format "Man(%s)" section)
                  :finder (t-finders.new_table
                            {:results entries
                             :entry_maker
                             (let [base (t-entry.gen_from_apropos opts)]
                               (fn [line]
                                 (let [entry (base line)]
                                   (set entry.value
                                        (string.format
                                          "%s(%s)" entry.value section))
                                   entry)))})
                  :previewer (man-previewer.new opts)
                  :sorter (t-sorters.get_fzy_sorter opts)
                  :attach_mappings action-mapper})]
    (picker:find)))
