(local python (require "my.lang.python"))
(local b (require "my.bufreg"))
(local fun (require "fun.raw"))

(fn table-concat [...]
  (local result {})
  (var pos 1)
  (for [i 1 (select :# ...)]
    (let [tbl (select i ...)]
      (when tbl
        (for [j 1 (length tbl)]
          (let [val (. tbl j)]
            (when val
              (tset result pos val)
              (set pos (+ pos 1))))))))
  result)



(local default-configuration
  ["--implicit-optional"
   "--allow-redefinition"

   "--check-untyped-defs"

   "--disallow-any-generics"
   "--disallow-subclassing-any"
   "--disallow-incomplete-defs"
   "--disallow-untyped-calls"
   "--disallow-untyped-decorators"
   "--disallow-untyped-defs"

   "--disallow-any-unimported"
   "--no-implicit-reexport"

   "--strict-equality"

   "--warn-incomplete-stub"
   "--warn-redundant-casts"
   "--warn-unused-ignores"
   "--warn-return-any"])


(local display-configuration
  ["--show-column-numbers"
   "--show-error-codes"
   "--no-pretty"
   "--no-error-summary"
   "--no-color-output"])


(local mypy-module (python.run-module-arg "mypy"))


(local line-pattern "([^:]+):(%d+):(%d+): ([^:]+): (.*)")


(fn mypy-parse [{: output : cwd}]
  (local call vim.api.nvim_call_function)
  (icollect [_ line (fun.str-split "\n" output)]
    (do
      (local (name row col sev message) (string.match line line-pattern))
      (when name
        (local bufnr (call "bufadd" [(.. cwd "/" name)]))
        (local severity (match sev
                          :error 1
                          :warning 2
                          :note 3
                          _ 4))
        {:source "mypy"
         : bufnr
         : row
         : col
         : severity
         : message}))))


(local mypy-launcher
  {:dynamic_command (fn [params] (python.executable params.bufnr))
   :args (fn [params]
           (local bufnr params.bufnr)
           (local has-config (not= nil (b.get-local bufnr :python :mypy :config)))
           (table-concat ["-c" mypy-module]
                         (if has-config [] default-configuration)
                         display-configuration
                         ["--shadow-file" params.bufname params.temp_path
                          params.bufname]))
   :to_temp_file true
   :multiple_files true
   :temp_dir (.. _G.STDPATH.cache "/null-ls-tmp-mypy")
   :check_exit_code (fn [code] (<= code 2))
   :on_output (fn [params done]
                (LOG "Mypy done" :data params)
                (done (mypy-parse params)))})


(fn source []
  (local lsp (require "null-ls"))
  (local {: generator_factory
          : make_builtin} (require "null-ls.helpers"))
  (local mypy
    {:name "mypy"
     :filetypes [:python]
     :method [lsp.methods.DIAGNOSTICS lsp.methods.DIAGNOSTICS_ON_SAVE]
     :generator_opts mypy-launcher
     :factory generator_factory})
  (make_builtin mypy))
               
  
(source)
