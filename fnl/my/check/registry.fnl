(local u (require "my.util"))

(local registered-checkers {})
(local running-checkers {})


(fn get-default [tbl key]
  (var res (. tbl key))
  (when (= nil res)
    (set res {})
    (tset tbl key res))
  res)


(fn run [name bufnr ...]
  (let [checker (. registered-checkers name)
        state (checker.run bufnr ...)]
    (tset (get-default running-checkers bufnr) name
          {:bufnr bufnr
           :reg checker
           :state state})))


(fn cancel [name bufnr]
  (let [running (. running-checkers bufnr)
        runinfo (. running name)]
    (tset running name nil)
    (runinfo.reg.cancel bufnr runinfo.state)))


(fn running? [bufnr name]
  (~= (u.nget running-checkers name bufnr) nil))


(fn register [name run-fn cancel-fn]
  (tset registered-checkers name
        {:name name
         :run run-fn
         :cancel cancel-fn}))


{: run 
 : cancel 
 : running? 
 : register} 
