(module my.treesitter
  {require {ts nvim-treesitter.configs}})


(defn- configure []
  (ts.setup
    {:highlight {:enable true
                 :disable [:css]}
     :rainbow {:enable true}
     :playground {:enable true
                  :disable {}
                  :updatetime 25
                  :persist_queries false}
     :query_linter {:enable true
                    :use_virtual_text true
                    :lint_events [:BufWrite :CursorHold]}}))


(defn setup []
  (configure))
