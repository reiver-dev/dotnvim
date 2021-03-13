(module my.async
  {require {v my.vararg
            u my.util}})

(require-macros :my.validate-macros)
(require-macros :my.coroutine-macros)

(def- nothing u.nothing)
(def- argpack v.pack)
(def- argunpack v.unpack)
(def- argunpack-tail v.unpack-tail)

(def- callable? vim.is_callable)

(defn- default-error [thread msg]
  (debug.traceback thread msg))


(defn- proceed [coro finally onerror continuation status ...]
  (if status
    (if (coro-dead? coro)
      (finally true ...)
      (let [callback ...] (callback continuation)))
    (finally false (onerror coro ...))))


(defn- resume [coro finally err continuation ...]
  (proceed coro finally err continuation (coro-resume coro ...)))


(defn- maybe-create [func]
  (if (callable? func)
    (coroutine.create func)
    (if (coro? func)
      (let [status (coroutine.status func)]
        (if (= status "suspended")
          func
          (error (string.format
                   "Coroutine status `suspended` expected, got `%s`"
                   status))))
      (error "Function or coroutine expected"))))


(defn step [func callback onerror ...]
  (validate func callable? coro?)
  (validate onerror nil? callable?)
  (let [coro (maybe-create func)
        finally (or callback nothing) 
        err (or onerror default-error)]
    (var continuation nil)
    (set continuation (fn [...]
                        (resume coro finally err continuation ...)))
    (resume coro finally onerror continuation ...)))


(defn- bind-but-last-argument [func ...]
  (match (select :# ...)
    0 func
    1 (let [arg1 ...]
        (fn [continuation] (func arg1 continuation)))
    2 (let [(arg1 arg2) ...]
        (fn [continuation] (func arg1 arg2 continuation)))
    3 (let [(arg1 arg2 arg3) ...]
        (fn [continuation] (func arg1 arg2 arg3 continuation)))
    _ (let [args (argpack ...)]
        (fn [continuation] (func (argunpack-tail args continuation))))))


(defn from-callback [func]
  (validate func callable?)
  (fn [...] (bind-but-last-argument func ...)))


(defn wrap-coro [func onerror ...]
  (let [num (select :# ...)]
    (match num
      ;; No arg
      0 (fn [continuation]
          (step func continuation onerror))
      ;; Single arg
      1 (let [value ...]
          (fn [continuation]
            (step func continuation onerror value)))
      ;; Two arg
      2 (let [(value1 value2) ...]
          (fn [continuation]
            (step func continuation onerror value1 value2)))
      ;; Varargs
      _ (let [params (argpack ...)]
          (fn [continuation]
            (step func continuation onerror (argunpack params)))))))


(defn wrap-vim [func]
  (fn [continuation]
    (vim.schedule
      (fn [] (continuation (pcall func))))))


(defn wait-callback [func ...]
  (validate func callable?)
  (coro-yield (bind-but-last-argument func ...)))


(defn wait [...]
  (coro-yield ...))


(defn- gather-impl [coros callback]
  (validate callback callable?)
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
          (coro cb))))))


(defn gather [coros]
  (fn [callback]
    (gather-impl coros callback)))


(defn- iter-wait-state-decrement [state idx]
  (let [n (- state.n 1)]
    (set state.n n)
    n))


(defn- iter-wait-impl [state idx]
  (when (or (= idx 0)
            (> (iter-wait-state-decrement state idx) 0))
    (coro-yield state.iter)))


(defn- iter-wait-state [num]
  (let [self {:n num}]
    (set self.iter (fn [callback] (set self.resume callback)))
    self))


(defn iter [coros]
  (let [state (iter-wait-state (length coros))]
    (each [idx coro (ipairs coros)]
      (coro (fn [...] (state.resume idx ...))))
    (values iter-wait-impl state 0)))


(defn block [func timeout interval]
  (validate func callable?)
  (validate timeout nil? number?)
  (validate interval nil? number?)
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
