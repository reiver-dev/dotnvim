;;; Telescope file-browser


(fn upvalues-iter [state idx]
  (local idx (+ idx 1))
  (local (name value) (debug.getupvalue state idx))
  (when (not= name nil)
    (values idx name value)))


(fn upvalues [func]
  (values upvalues-iter func 0))


(fn update-separator [func]
  (local slash (if _G.SHELLSLASH "/" "\\"))
  (each [i name val (upvalues func)]
    (when (= name "os_sep")
      (debug.setupvalue func i slash))))


(fn update-separator-mt [func]
  (each [i name val (upvalues func)]
    (when (= name "mt")
      (update-separator val.display))))


(fn shellslash-entry-maker []
  (local base-entry-maker (require "telescope._extensions.file_browser.make_entry"))
  (local base-opts {:entry_cache {}})
  (fn [opts]
    (local make-entry (base-entry-maker (vim.tbl_extend :force base-opts opts)))
    (update-separator-mt make-entry)
    make-entry))


(fn find-file []
  (local telescope (require "telescope"))
  (local themes (require "telescope.themes"))
  (local em (if (vim.fn.has "win32") (shellslash-entry-maker) nil))
  (telescope.extensions.file_browser.file_browser
    (themes.get_ivy {:previewer false
                     :entry_maker em})))


(fn setup []
  (local t (require "telescope"))
  (t.load_extension :file_browser)
  (vim.api.nvim_set_keymap
    :n "<C-x>f" "<cmd>lua _T('my.pack.telescope-file-browser', 'find-file')<CR>" {:noremap true}))


{: setup : find-file}
