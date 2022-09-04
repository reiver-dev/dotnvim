(module my.treesitter
  {require {ts nvim-treesitter.configs}})


(defn- current-size []
  (+ (vim.fn.line2byte "$") (- (vim.fn.col "$") 1)))


(defn- current-size-buf [bufnr]
  (vim.api.nvim_buf_call bufnr current-size))


(defn- shellslash-normalize [str ...]
  (if str
    (values (string.gsub str "/" "\\") ...)
    (values str ...)))


(defn- shellslash-patch []
  (local utils (require "nvim-treesitter.utils"))
  (each [_ name (ipairs [:get_package_path :get_site_dir :get_cache_dir])]
    (let [func (. utils name)]
      (tset utils name (fn [] (shellslash-normalize (func)))))))


(def- disabled-langs
  {:css true})


(def- size-limit-langs
  {:cpp 5_000_000})


(defn- too-big? [lang bufnr]
  (local sz (. size-limit-langs lang))
  (and sz (< 0 sz) (< sz (current-size-buf bufnr))))


(defn- disable-highlight? [lang bufnr]
  (and (not (. disabled-langs lang))
       (not (too-big? lang bufnr))))


(defn- configure []
  (when (= 1 (vim.fn.has "win32")) (shellslash-patch))
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


(defn setup []
  (when _G.packer_plugins.neorg
    (_T :my.pack.neorg.treesitter :setup))
  (configure))
