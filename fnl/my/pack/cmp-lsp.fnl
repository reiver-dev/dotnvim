(local PARDIR (vim.fs.joinpath _G.STDPATH.state "my/"))
(local PATH (vim.fs.joinpath _G.STDPATH.state "my/lsp-cap-cmp.json"))

(fn spew [path text]
  (local f (assert (vim.uv.fs_open PATH "w" (tonumber "644" 8))))
  (local (_ err) (vim.uv.fs_write f text))
  (vim.uv.fs_close f)
  (when err (error err)))
  

(fn reset-impl []
  (local caps (vim.json.encode (_T :cmp_nvim_lsp :default_capabilities)
                               {:indent "  "}))
  (vim.fn.mkdir PARDIR "p")
  (spew PATH caps))
                  

(fn reset []
  (if (vim.in_fast_event)
    (vim.schedule reset-impl))
  (reset-impl))


(fn setup [])


{: setup
 : reset}
