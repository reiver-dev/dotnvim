(fn current-size []
  (+ (vim.fn.line2byte "$") (- (vim.fn.col "$") 1)))


(fn current-size-buf [bufnr]
  (vim.api.nvim_buf_call bufnr current-size))


(fn shellslash-normalize [str ...]
  (if str
    (values (string.gsub str "/" "\\") ...)
    (values str ...)))


(fn shellslash-patch []
  (local utils (require "nvim-treesitter.utils"))
  (each [_ name (ipairs [:get_package_path :get_site_dir :get_cache_dir])]
    (let [func (. utils name)]
      (tset utils name (fn [] (shellslash-normalize (func)))))))


(local disabled-langs
  {:css true})


(local size-limit-langs
  {:cpp 5_000_000})


(fn too-big? [lang bufnr]
  (local sz (. size-limit-langs lang))
  (and sz (< 0 sz) (< sz (current-size-buf bufnr))))


(fn disable-highlight? [lang bufnr]
  (and (not (. disabled-langs lang))
       (not (too-big? lang bufnr))))


(fn configure []
  (when (= 1 (vim.fn.has "win32")) (shellslash-patch))
  (local ts (require "nvim-treesitter.configs"))
  (ts.setup
    {:highlight {:enable true
                 :disable disable-highlight?}
     :playground {:enable true
                  :disable {}
                  :updatetime 25
                  :persist_queries false}
     :query_linter {:enable true
                    :use_virtual_text true
                    :lint_events [:BufWrite :CursorHold]}}))


(fn setup []
  (when _G.packer_plugins.neorg
    (_T :my.pack.neorg.treesitter :setup))
  (configure))


{: setup}
