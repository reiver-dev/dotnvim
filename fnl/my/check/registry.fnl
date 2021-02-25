(module my.check.registry
  {require {u my.util}})


(defonce- registered-checkers {})
(defonce- running-checkers {})


(defn- get-default [tbl key]
  (var res (. tbl key))
  (when (= nil res)
    (set res {})
    (tset tbl key res))
  res)


(defn run [name bufnr ...]
  (let [checker (. registered-checkers name)
        state (checker.run bufnr ...)]
    (tset (get-default running-checkers bufnr) name
          {:bufnr bufnr
           :reg checker
           :state state})))


(defn cancel [name bufnr]
  (let [running (. running-checkers bufnr)
        runinfo (. running name)]
    (tset running name nil)
    (runinfo.reg.cancel bufnr runinfo.state)))


(defn running? [bufnr name]
  (~= (u.nget running-checkers name bufnr) nil))


(defn register [name run-fn cancel-fn]
  (tset registered-checkers name
        {:name name
         :run run-fn
         :cancel cancel-fn}))
