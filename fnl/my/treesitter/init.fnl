(module my.treesitter
  {require {ts nvim-treesitter.configs}})


(defn- current-size []
  (+ (vim.fn.line2byte "$") (- (vim.fn.col "$") 1)))


(defn- supported [query-checker lang]
  (and (or (not= lang "cpp") (<= (current-size) 5_000_000))
       (_T :nvim-treesitter.query query-checker lang)))


(defn- configure []
  (ts.setup
    {:highlight {:enable true
                 :is_supported (partial supported :has_highlights)
                 :disable [:css]}
     :rainbow {:enable true
               :is_supported (partial supported :has_highlights)}
     :playground {:enable true
                  :disable {}
                  :updatetime 25
                  :persist_queries false}
     :query_linter {:enable true
                    :use_virtual_text true
                    :lint_events [:BufWrite :CursorHold]}}))


(defn setup []
  (configure))
