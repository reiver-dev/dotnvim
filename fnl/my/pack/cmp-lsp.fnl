(local PARDIR (vim.fs.joinpath _G.STDPATH.state "my/"))
(local PATH (vim.fs.joinpath _G.STDPATH.state "my/lsp-cap-cmp.json"))

(fn spew [path text]
  (local f (assert (vim.uv.fs_open PATH "w" (tonumber "644" 8))))
  (local (_ err) (vim.uv.fs_write f text))
  (vim.uv.fs_close f)
  (when err (error err)))
  

(fn reset-impl [pkg]
  (LOAD_PACKAGE pkg.spec.name)
  (local caps (vim.json.encode (_T :cmp_nvim_lsp :default_capabilities)
                               {:indent "  "}))
  (vim.fn.mkdir PARDIR "p")
  (spew PATH caps))
                  

(fn reset [pkg]
  (if (vim.in_fast_event)
    (vim.schedule (fn [] (reset-impl pkg))))
  (reset-impl pkg))


(fn setup [])


{: setup
 : reset}
