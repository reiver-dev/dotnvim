(module my.telescope.man
  {require {t-entry telescope.make_entry
            t-finders telescope.finders
            t-pickers telescope.pickers
            t-sorters telescope.sorters
            t-previewers telescope.previewers
            t-actions telescope.actions
            t-utils telescope.utils
            t-conf telescope.config
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


(defn- did-ftplugin? [bufnr]
  (let [(ok res) (pcall #(vim.api.nvim_buf_get_var bufnr :did_ftplugin))]
    (and ok (= res 1))))


(defn- man-buffer-highlight [bufnr]
  (let [hl (. (require "man") :highlight_man_page)]
    (vim.api.nvim_buf_call bufnr hl)))


(defn- erzatz-man-filetype [bufnr ?section]
  (when (not (did-ftplugin? bufnr))
    (man-buffer-highlight bufnr)
    (vim.api.nvim_buf_set_var bufnr :did_ftplugin 1)
    (vim.api.nvim_buf_set_var bufnr :man_sect (or ?section ""))
    (vim.api.nvim_buf_set_option bufnr :filetype "man")
    (vim.api.nvim_buf_set_option bufnr :iskeyword
                                 "@-@,:,a-z,A-Z,48-57,_,.,-,(,)")))


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
           (let [command ["man" entry.section entry.value]
                 env (process-environment
                       {"MANPAGER" "cat"
                        "MAN_KEEP_FORMATTING" "1"
                        "MANWIDTH" (vim.api.nvim_win_get_width self.state.winid)})]
             ;; Run man
             (t-putils.job_maker command self.state.bufnr
                                 {:env env
                                  :callback (fn [bufnr]
                                              (erzatz-man-filetype bufnr entry.section))
                                  :value entry.value
                                  :bufname self.state.bufname})))}))))


(defn- call-selection-command [command]
  (fn [bufnr]
    (let [selection (t-actions.get_selected_entry)]
      (t-actions.close bufnr)
      (vim.cmd (command:format selection.section selection.value)))))


(def- man-edit (call-selection-command "Man %s %s"))
(def- man-hsplit (call-selection-command "Man %s %s"))
(def- man-vsplit (call-selection-command "vert bo Man %s %s"))
(def- man-tabedit (call-selection-command "tab Man %s %s"))


(defn- action-mapper [bufnr]
  (let [r #($1:replace $2)]
    (r t-actions.select_default man-edit)
    (r t-actions.select_horizontal man-hsplit)
    (r t-actions.select_vertical man-vsplit)
    (r t-actions.select_tab man-tabedit))
  true)


(defn- empty? [array]
  (or (not array) (= (length array) 0)))


(defn- os-darwin? []
  (= (. (vim.loop.os_uname) :sysname) "Darwin"))


(defn- man-picker [opts]
  (local search-cmd
    [opts.man_cmd (.. "--sections=" (table.concat opts.sections ",")) opts.man_pattern])
  {:prompt_title (string.format "Man(%s)" (table.concat opts.sections ", "))
   :finder (t-finders.new_oneshot_job search-cmd opts)
   :previewer (man-previewer.new opts)
   :sorter (t-conf.values.generic_sorter opts)
   :attach_mappings action-mapper})


(defn manpages [opts]
  (local opts (or opts {}))

  (match (type opts.sections)
    "string" (set opts.sections [opts.sections])
    "nil" (set opts.sections ["1"]))

  (when (empty? opts.man_pattern)
    (set opts.man_pattern (if (os-darwin?) " " "")))

  (when (empty? opts.man_cmd)
    (set opts.man_cmd "apropos"))

  (when (not opts.entry_maker)
    (set opts.entry_maker (t-entry.gen_from_apropos opts)))

  (-> (t-pickers.new opts (man-picker opts))
      (: :find)))
