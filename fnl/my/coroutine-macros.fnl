;;; Coroutine shortcut macros

(fn coro-dead? [coro]
  `(= (coroutine.status ,coro) "dead"))

(fn coro-alive? [coro]
  `(not= (coroutine.status ,coro) "dead"))

(fn coro-resume [coro ...]
  `(coroutine.resume ,coro ,...))

(fn coro-yield [...]
  `(coroutine.yield ,...)) 

(fn coro-status [coro]
  `(coroutine.status ,coro)) 


{: coro-dead?
 : coro-alive?
 : coro-resume
 : coro-yield
 : coro-status}


;;; coroutine-macros.fnl ends here
