(local a (require "my.async"))
(local s (require "my.simple"))
(local v (require "my.vararg"))

(local COMPLETED 0)
(local STATUS 1) 
(local WAIT 2)
(local INSPECT 3)


(fn timeout-expired [timeout]
  (let [funcname (. (debug.getinfo 2 :n) :name)
        {: short_src : linedefined } (. (debug.getinfo 3))]
    (error (string.format "%s:%s: Timeout %d expired"
                          short_src linedefined timeout))))



(fn error-message [function]
  (let [info (debug.getinfo function :S)]
    (string.format "Error during running async %s:%d\n"
                   info.short_src info.linedefined)))


(fn block-impl [context timeout interval]
  (vim.validate {:timeout [timeout :number true]
                 :interval [interval :number true]})
  (let [tm (or timeout 200)
        ii (or interval 200)
        res (vim.wait tm (fn [] context.completed) ii)]
    (if (= res true)
      (v.unpack context.result)
      (timeout-expired tm))))


(fn finalizer [context]
  (fn [status ...]
    (set context.result (v.pack ...))
    (set context.completed true)
    (set context.success status)
    (when (not status)
      (s.errmsg (error-message context.func) ...))))
    

(fn status-impl [context]
  (when context.coro
    (coroutine.status context.coro)))


(fn new [asyncfunc ...]
  (let [context {:completed false
                 :func asyncfunc
                 :coro (coroutine.create asyncfunc)}]
    (set context.step (a.step context.coro (finalizer context) nil ...))
    (fn [message ...]
      (match message
        COMPLETED context.completed
        STATUS (status-impl context)
        WAIT (block-impl context ...)
        INSPECT (vim.inspect context)))))


(fn completed? [cb]
  (cb COMPLETED))


(fn status [cb]
  (cb STATUS))


(fn wait [cb timeout interval]
  (cb WAIT timeout interval))


(fn inspect [cb]
  (cb INSPECT))


{: new
 : completed?
 : status
 : wait
 : inspect}
