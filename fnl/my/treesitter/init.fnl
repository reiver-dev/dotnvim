(module my.treesitter
  {require {ts nvim-treesitter.configs}})


(defn- current-size []
  (+ (vim.fn.line2byte "$") (- (vim.fn.col "$") 1)))


(defn- supported [query-checker lang]
  (and (or (not= lang "cpp") (<= (current-size) 5_000_000))
       (_T :nvim-treesitter.query query-checker lang)))


(defn- shellslash-normalize [str ...]
  (if str
    (values (string.gsub str "/" "\\") ...)
    (values str ...)))


(defn- shellslash-patch []
  (local utils (require "nvim-treesitter.utils"))
  (each [_ name (ipairs [:get_package_path :get_site_dir :get_cache_dir])]
    (let [func (. utils name)]
      (tset utils name (fn [] (shellslash-normalize (func)))))))


(defn- configure []
  (when (= 1 (vim.fn.has "win32")) (shellslash-patch))
  (ts.setup
    {:highlight {:enable true
                 :is_supported (partial supported :has_highlights)
                 :disable [:css]}
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
