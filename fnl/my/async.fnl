(local v (require "my.vararg"))

(local coroutine _G.coroutine)

(require-macros :my.validate-macros)
(require-macros :my.coroutine-macros)

(fn nothing [] nil)
(local argpack v.pack)
(local argunpack v.unpack)
(local argunpack-tail v.unpack-tail)

(local callable? vim.is_callable)

(fn default-error [thread msg]
  (debug.traceback thread msg))


(fn proceed [coro finally onerror continuation status ...]
  (if status
    (if (coro-dead? coro)
      (finally true ...)
      (let [callback ...] (callback continuation)))
    (finally false (onerror coro ...))))


(fn resume [coro finally onerror continuation ...]
  (proceed coro finally onerror continuation (coro-resume coro ...)))


(fn maybe-create [func]
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


(fn step [func callback onerror ...]
  (validate func callable? coro?)
  (validate onerror nil? callable?)
  (let [coro (maybe-create func)
        finally (or callback nothing)
        onerror (or onerror default-error)]
    (fn continuation [...]
      (resume coro finally onerror continuation ...))
    (proceed coro finally onerror continuation (coro-resume coro ...))))


(local callback-bind-template
  "return function(func)
    return function(%A)
      return function(continuation)
        return func(%A %D continuation)
      end
    end
  end")


(local coro-bind-template
  "return function(step, func, onerror)
    return function (%A)
      return function(continuation)
        return step(func, onerror %D %A)
      end
    end
  end")


(local callback-wrap-template
  "return function(func %D %A)
    return function(continuation)
      return func(%A %D continuation)
    end
  end")


(local coro-wrap-template
  "return function(step, func, onerror %D %A)
    return function(continuation)
      return step(func, continuation, onerror %D %A)
    end
  end")


(local vim-wrap-template
  "return function(func %D %A)
    return function(continuation)
      vim.schedule(function() continuation(pcall(func %D %A)) end)
    end
  end")


(fn argument-sequence [num]
  (var result [])
  (for [i 1 num]
    (tset result i (.. "arg" (tostring i))))
  (table.concat result ","))


(fn forbidden []
  (error "Table insertion is forbidden."))


(fn bind-vararg [template numargs chunkname]
  ((loadstring (string.gsub template
                           "%%[A-Z]" {"%A" (argument-sequence numargs)
                                      "%D" (or (and (< 0 numargs) ",") "")})
               chunkname)))


(fn make-vararg-binder [template chunkname]
  (fn [tbl num]
    (let [func (bind-vararg template num (if (not= nil chunkname)
                                           (.. chunkname "_" (tostring num))
                                           nil))]
      (rawset tbl num func)
      func)))


(local bind-callback-cache
  (setmetatable {} {:__index (make-vararg-binder callback-bind-template "bind_cb")
                    :__newindex forbidden}))


(local bind-coro-cache
  (setmetatable {} {:__index (make-vararg-binder coro-bind-template "bind_coro")
                    :__newindex forbidden}))


(local wrap-callback-cache
  (setmetatable {} {:__index (make-vararg-binder callback-wrap-template "wrap_cb")
                    :__newindex forbidden}))


(local wrap-coro-cache
  (setmetatable {} {:__index (make-vararg-binder coro-wrap-template "wrap_coro")
                    :__newindex forbidden}))


(local wrap-vim-cache
  (setmetatable {} {:__index (make-vararg-binder vim-wrap-template "bind_vim")
                    :__newindex forbidden}))


;; FROM functions return (fn [...] (fn [continuation] ...))
(fn from-callback [func numargs]
  (validate func callable?)
  (if numargs
    ((. bind-callback-cache numargs) func)
    (fn [...] ((. wrap-callback-cache (select :# ...)) func ...))))


(fn from-coro [func numargs]
  (if numargs
    ((. bind-coro-cache numargs) func)
    (fn [...] ((. wrap-coro-cache (select :# ...)) step func nil ...))))


;; WRAP functions return (fn [continuation] ...)
(fn wrap-callback [func ...]
  ((. wrap-callback-cache (select :# ...)) func ...))


(fn wrap-coro [func ...]
  ((. wrap-coro-cache (select :# ...)) step func nil ...))


(fn wrap-vim [func ...]
  ((. wrap-vim-cache (select :# ...)) func ...))


;; WAIT functions yield (fn [continuation] ...)
(fn wait-vim [func ...]
  (coro-yield (wrap-vim func ...)))


(fn wait-coro [func ...]
  (coro-yield (wrap-coro func nil ...)))


(fn wait-callback [func ...]
  (coro-yield (wrap-callback func ...)))


(fn wait [awaitable]
  (coro-yield awaitable))


;; Helper to run coroutine detached
(fn error-message [function]
  (let [info (debug.getinfo function :S)]
    (string.format "Error during running async %s:%d\n"
                   info.short_src info.linedefined)))


(fn finalizer [context]
  (fn [status ...]
    (set context.result (argpack ...))
    (set context.completed true)
    (set context.success status)
    (when (not status)
      (vim.schedule
        (fn []
          (vim.notify (.. (error-message context.func) (. context.result 0))
                    vim.log.levels.ERROR))))))


(fn run [func ...]
  (let [context {:completed false
                 :func func
                 :coro (coroutine.create func)}]
    (set context.step (step context.coro (finalizer context) nil ...))
    context))


(fn gather-impl [coros callback]
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


(fn gather [coros]
  (fn [callback]
    (gather-impl coros callback)))


(fn iter-wait-state-decrement [state idx]
  (let [n (- state.n 1)]
    (set state.n n)
    n))


(fn iter-wait-impl [state idx]
  (when (or (= idx 0)
            (> (iter-wait-state-decrement state idx) 0))
    (coro-yield state.iter)))


(fn iter-wait-state [num]
  (let [self {:n num}]
    (set self.iter (fn [callback] (set self.resume callback)))
    self))


(fn iter [coros]
  (let [state (iter-wait-state (length coros))]
    (each [idx coro (ipairs coros)]
      (coro (fn [...] (state.resume idx ...))))
    (values iter-wait-impl state 0)))


(fn block [func timeout interval]
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


{: iter
 : block
 : gather
 : step
 : run
 : from-coro
 : from-callback
 : wrap-vim
 : wrap-coro
 : wrap-callback
 : wait-vim
 : wait-coro
 : wait-callback
 : wait}
