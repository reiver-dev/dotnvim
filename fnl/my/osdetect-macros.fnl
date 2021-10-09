;;; Detect os in macro scope


(local osname _SYSNAME)

(assert (and (not= nil osname) (not= "" osname))
        "Empty osname")


(local os-posix
  {:Darwin true
   :Linux true
   :Unix true
   :Windows false
   :Windows_NT false
   :MINGW32_NT false})


(local os-win
  {:Windows true
   :Windows_NT true
   :MINGW32_NT true})


(local this-posix (or (. os-posix osname) false))
(local this-windows (or (. os-win osname) false))
(local this-macos (= osname :Darwin))


(when (not (or this-posix this-windows))
  (error (.. "Unknown os class: " osname)))


(fn sysname []
  osname)


(fn posix? []
  this-posix)


(fn windows? []
  this-windows)


(fn macos? []
  this-macos)


(local when-posix (if this-posix
                    (fn when-posix [...] ...)
                    (fn when-posix [...])))


(local when-macos (if this-macos
                    (fn when-macos [...] ...)
                    (fn when-macos [...])))


(local when-windows (if this-windows
                      (fn when-win [...] ...)
                      (fn when-win [...])))


{: sysname
 : posix?
 : windows?
 : macos?
 : when-windows
 : when-posix
 : when-macos}
