(module my.async
  {require {v my.vararg
            u my.util}})


(def- nothing u.nothing)
(def- argpack v.pack)
(def- argunpack v.unpack)
(def- argunpack-tail v.unpack-tail)


(defn- default-error [thread msg]
  (debug.traceback thread msg))


(defn- coro-dead? [coro] (= (coroutine.status coro) "dead"))
(defn- coro-alive? [coro] (not= (coroutine.status coro) "dead"))


(defn- proceed [coro finally err continuation status ...]
  (if status
    (if (coro-dead? coro)
      (finally true ...)
      (let [callback ...] (callback continuation)))
    (finally false (err coro ...))))


(defn- resume [coro finally err continuation ...]
  (proceed coro finally err continuation (coroutine.resume coro ...)))


(defn- maybe-create [func]
  (if (vim.is_callable func)
    (coroutine.create func)
    (if (= (type func) "thread")
      (let [status (coroutine.status func)]
        (if (= status "suspended")
          func
          (error (string.format
                   "Coroutine status `suspended` expected, got `%s`"
                   status))))
      (error "Function or coroutine expected"))))
    

(defn step [func callback err ...]
  (vim.validate {:callback [callback :function true]
                 :err [err :function true]})
  (let [coro (maybe-create func)
        finally (or callback nothing) 
        onerror (or err default-error)]
    (var tick nil)
    (set tick (fn [...] (resume coro finally onerror tick ...)))
    (resume coro finally onerror tick ...)))


(defn wrap [func]
  (vim.validate {:func [func :function]})
  (fn [...]
    (let [params (argpack ...)]
      (fn [tick]
        (func (argunpack-tail params tick))))))


(defn igather [coros]
  (fn [callback]
    (vim.validate {:gather-callback [callback :f]})
    (if (vim.tbl_isempty coros)
      (callback)
      (let [count (length coros)
            results []]
        (var done 0)
        (each [i coro (ipairs coros)]
          (let [cb (fn [...]
                     (tset results i (argpack ...))
                     (set done (+ done 1))
                     (when (= count done)
                       (callback results)))]
            (coro cb)))))))


(defn gather [coros]
  (fn [callback]
    (vim.validate {:gather-callback [callback :f]})
    (if (vim.tbl_isempty coros)
      (callback)
      (let [count (length coros)
            results []]
        (var done 0)
        (each [i coro (pairs coros)]
          (let [cb (fn [...]
                     (tset results i (argpack ...))
                     (set done (+ done 1))
                     (when (= count done)
                       (callback results)))]
            (coro cb)))))))


(defn wait [...]
  (coroutine.yield ...))


(defn sync [func err ...]
  (if (< 0 (select :# ...))
    (let [params (argpack ...)]
      (fn [tick] (step func tick err (argunpack params))))
    (fn [tick] (step func tick err))))
  

(defn main [func]
  (vim.schedule func))


(defn block [func timeout interval]
  (vim.validate {:timeout [timeout :number true]
                 :interval [interval :number true]
                 :func [func :function]})
  (var context {:completed false})
  (step func (fn [...]
               (set context.result (argpack ...))
               (set context.completed true)))
  (let [tm (or timeout 200)
        res (vim.wait tm (fn [] context.completed) (or interval 200))]
    (if (= res true)
      ;; Return function result (ok, ...)
      (argunpack context.result)
      ;; Describe timeout error
      (let [funcname (. (debug.getinfo 1 :n) :name)
            {: short_src : linedefined } (. (debug.getinfo 2))]
        (error (string.format "%s:%s: Timeout %d expired"
                              short_src linedefined tm))))))