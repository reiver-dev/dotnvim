;;; Telescope file-browser

(fn find-file []
  (local telescope (require "telescope"))
  (local themes (require "telescope.themes"))
  (telescope.extensions.file_browser.file_browser
    (themes.get_ivy {:previewer false})))


(fn setup []
  (local t (require "telescope"))
  (t.load_extension :file_browser)
  (vim.api.nvim_set_keymap
    :n "<C-x>f" "<cmd>lua _T('my.pack.telescope-file-browser', 'find-file')<CR>" {:noremap true}))


{: setup : find-file}
