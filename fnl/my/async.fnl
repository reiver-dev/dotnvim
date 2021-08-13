(module my.async
  {require {v my.vararg}})

(def- coroutine _G.coroutine)

(require-macros :my.validate-macros)
(require-macros :my.coroutine-macros)

(defn- nothing [] nil)
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


(defn- resume [coro finally onerror continuation ...]
  (proceed coro finally onerror continuation (coro-resume coro ...)))


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
        onerror (or onerror default-error)]
    (var continuation nil)
    (set continuation (fn [...]
                        (resume coro finally onerror continuation ...)))
    (proceed coro finally onerror continuation (coro-resume coro ...))))


(def- callback-bind-template
  "return function(func)
    return function(%A)
      return function(continuation)
        return func(%A %D continuation)
      end
    end
  end")


(def- coro-bind-template
  "return function(step, func, onerror)
    return function (%A)
      return function(continuation)
        return step(func, onerror %D %A)
      end
    end
  end")


(def- callback-wrap-template
  "return function(func %D %A)
    return function(continuation)
      return func(%A %D continuation)
    end
  end")


(def- coro-wrap-template
  "return function(step, func, onerror %D %A)
    return function(continuation)
      return step(func, continuation, onerror %D %A)
    end
  end")


(def- vim-wrap-template
  "return function(func %D %A)
    return function(continuation)
      vim.schedule(function() continuation(pcall(func %D %A)) end)
    end
  end")


(defn- argument-sequence [num]
  (var result [])
  (for [i 1 num]
    (tset result i (.. "arg" (tostring i))))
  (table.concat result ","))


(defn- forbidden []
  (error "Table insertion is forbidden."))


(defn- bind-vararg [template numargs]
  ((loadstring (string.gsub template
                           "%%[A-Z]" {"%A" (argument-sequence numargs)
                                      "%D" (or (and (< 0 numargs) ",") "")}))))


(defn- make-vararg-binder [template]
  (fn [tbl num]
    (let [func (bind-vararg template num)]
      (rawset tbl num func)
      func)))


(defn- make-callback-binder [tbl num]
  (let [args (argument-sequence num)
        func ((loadstring (string.format callback-bind-template args args)))]
    (rawset tbl num func)
    func))


(defn- make-callback-wrapper [tbl num]
  (let [args (argument-sequence num)
        func ((loadstring (string.format callback-wrap-template args args)))]
    (rawset tbl num func)
    func))


(defn- make-coro-wrapper [tbl num]
  (let [args (argument-sequence num)
        func ((loadstring (string.format coro-bind-template args args)))]
    (rawset tbl num func)
    func))


(def- bind-callback-cache
  (setmetatable {} {:__index (make-vararg-binder callback-bind-template)
                    :__newindex forbidden}))


(def- bind-coro-cache
  (setmetatable {} {:__index (make-vararg-binder coro-bind-template)
                    :__newindex forbidden}))


(def- wrap-callback-cache
  (setmetatable {} {:__index (make-vararg-binder callback-wrap-template)
                    :__newindex forbidden}))


(def- wrap-coro-cache
  (setmetatable {} {:__index (make-vararg-binder coro-wrap-template)
                    :__newindex forbidden}))


(def- wrap-vim-cache
  (setmetatable {} {:__index (make-vararg-binder vim-wrap-template)
                    :__newindex forbidden}))


;; FROM functions return (fn [...] (fn [continuation] ...))
(defn from-callback [func numargs]
  (validate func callable?)
  (if numargs
    ((. bind-callback-cache numargs) func)
    (fn [...] ((. wrap-callback-cache (select :# ...)) func ...))))


(defn from-coro [func numargs]
  (if numargs
    ((. bind-coro-cache numargs) func)
    (fn [...] ((. wrap-coro-cache (select :# ...)) step func nil ...))))


;; WRAP functions return (fn [continuation] ...)
(defn wrap-callback [func ...]
  ((. wrap-callback-cache (select :# ...)) func ...))


(defn wrap-coro [func ...]
  ((. wrap-coro-cache (select :# ...)) step func nil ...))


(defn wrap-vim [func ...]
  ((. wrap-vim-cache (select :# ...)) func ...))


;; WAIT functions yield (fn [continuation] ...)
(defn wait-vim [func ...]
  (coro-yield (wrap-vim func ...)))


(defn wait-coro [func ...]
  (coro-yield (wrap-coro func nil ...)))


(defn wait-callback [func ...]
  (coro-yield (wrap-callback func ...)))


(defn wait [awaitable]
  (coro-yield awaitable))


;; Helper to run coroutine detached
(defn- error-message [function]
  (let [info (debug.getinfo function :S)]
    (string.format "Error during running async %s:%d\n"
                   info.short_src info.linedefined)))


(defn- finalizer [context]
  (fn [status ...]
    (set context.result (argpack ...))
    (set context.completed true)
    (set context.success status)
    (when (not status)
      (vim.schedule
        (fn []
          (vim.notify (.. (error-message context.func) (. context.result 0))
                    vim.log.levels.ERROR))))))


(defn run [func ...]
  (let [context {:completed false
                 :func func
                 :coro (coroutine.create func)}]
    (set context.step (step context.coro (finalizer context) nil ...))
    context))


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
