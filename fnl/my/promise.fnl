(module my.promise
  {require {a my.async
            s my.simple
            v my.vararg}})


(def- COMPLETED 0)
(def- STATUS 1) 
(def- WAIT 2)
(def- INSPECT 3)


(defn- timeout-expired [timeout]
  (let [funcname (. (debug.getinfo 2 :n) :name)
        {: short_src : linedefined } (. (debug.getinfo 3))]
    (error (string.format "%s:%s: Timeout %d expired"
                          short_src linedefined timeout))))



(defn- error-message [function]
  (let [info (debug.getinfo function :S)]
    (string.format "Error during running async %s:%d\n"
                   info.short_src info.linedefined)))


(defn- block-impl [context timeout interval]
  (vim.validate {:timeout [timeout :number true]
                 :interval [interval :number true]})
  (let [tm (or timeout 200)
        ii (or interval 200)
        res (vim.wait tm (fn [] context.completed) ii)]
    (if (= res true)
      (v.unpack context.result)
      (timeout-expired tm))))


(defn- finalizer [context]
  (fn [status ...]
    (set context.result (v.pack ...))
    (set context.completed true)
    (set context.success status)
    (when (not status)
      (s.errmsg (error-message context.func) ...))))
    

(defn- status-impl [context]
  (when context.coro
    (coroutine.status context.coro)))


(defn new [asyncfunc ...]
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


(defn completed? [cb]
  (cb COMPLETED))


(defn status [cb]
  (cb STATUS))


(defn wait [cb timeout interval]
  (cb WAIT timeout interval))


(defn inspect [cb]
  (cb INSPECT))
