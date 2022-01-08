(local python (require "my.lang.python"))
(local b (require "my.bufreg"))

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


(fn parse-line [line]
  (print "PARSING:" line)
  (let [(name line col severity msg) (string.match line line-pattern)]
    (print "MATCH" name line col severity msg)
    (when name
      {:source "mypy"
       :row line
       :col col
       :severity (match severity
                   :error 1
                   :warning 2
                   :note 3
                   _ 4)
       :message msg})))


(fn prepare-args [{: bufnr : bufname : temp_path}])


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
   :check_exit_code (fn [code] (<= code 2))
   :format :line
   :on_output parse-line})


(fn setup []
  (local lsp (require "null-ls"))
  (local generator (lsp.generator mypy-launcher))
  (local mypy {:name "mypy"
               :filetypes [:python]
               :method lsp.methods.DIAGNOSTICS
               :generator generator})
  (local mypy-on-save {:name "mypy-on-save"
                       :filetypes [:python]
                       :method lsp.methods.DIAGNOSTICS_ON_SAVE
                       :generator generator})
  (lsp.register [mypy mypy-on-save]))


{: setup}
