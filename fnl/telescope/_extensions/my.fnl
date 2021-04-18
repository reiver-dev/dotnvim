(_T :telescope :register_extension
    {:exports
     {:manpages (fn [opts] (_T :my.telescope.man :manpages opts))}})
