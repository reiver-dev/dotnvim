(module my.checkers.mypy
  {require {b my.bufreg
            j my.check.job
            w my.fswalk
            p my.pathsep
            python my.lang.python}})


(local b (require "my.bufreg"))
(local j (require "my.check.job"))
(local w (require "my.fswalk"))
(local p (require "my.pathsep"))
(local python (require "my.lang.python"))


(local Error vim.diagnostic.severity.ERROR)
(local Warning vim.diagnostic.severity.WARN)
(local Information vim.diagnostic.severity.INFO)
(local Hint vim.diagnostic.severity.HINT)


(local line-pattern
  "([^:]+):(%d+):(%d+): ([^:]+): (.*)")


(fn parse-line [line]
  (let [(name line col severity msg) (string.match line line-pattern)]
    (when name
      (let [line (- (tonumber line) 1)
            col (- (tonumber col) 1)]
        {:source "mypy"
         :lnum line
         :end_lnum line
         :col col
         :end_col (+ col 1)
         :severity (match severity
                     :error Error
                     :note Information
                     :warning Warning
                     _ Hint)
         :message msg}))))


(fn parse-output [lines]
  (let [entries []]
    (each [_ line (ipairs lines)]
      (let [entry (parse-line line)]
        (when entry
          (table.insert entries entry))))
    entries))


(fn find-mypy-config [directory]
  (let [files (w.gather directory ["mypy.ini" "setup.cfg"])]
    (when files
      (or (-?> files (. :mypy.ini) (. 1))
          (-?> files (. :setup.cfg) (. 1))))))


(fn mypy-directory [bufnr]
  (let [dir (b.get-local bufnr :directory)
        cfg (find-mypy-config dir)
        launch-dir (or (and cfg (p.parent cfg)) dir)]
    (b.set-local bufnr :python :mypy :config cfg)
    (b.set-local bufnr :python :mypy :directory launch-dir)
    launch-dir))


(fn cut-prefix [str prefix]
  (local slen (length str))
  (local plen (length prefix))
  (if (and (<= plen slen) (= prefix (string.sub str 1 plen)))
    (values (string.sub str (+ plen 1)) (+ plen 1))
    (values str 0)))


(fn relative-path [path root]
  (p.trim (cut-prefix path root) p.separator?))


(fn handle-result [bufnr report-fn cleanup-fn jobid result]
  (cleanup-fn)
  (let [entries (parse-output result.stdout)]
    (report-fn entries))
  (LOG "Mypy Finished" :jobid jobid :result result))


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


(fn run [bufnr report-fn]
  (let [directory (mypy-directory bufnr)
        _ (LOG "Mypy directory" :dir directory)
        has-config (not= nil (b.get-local bufnr :python :mypy :config))
        current (relative-path (b.get-local bufnr :file) directory)
        tmpname (j.backup-buffer bufnr)
        cleanup-fn #(vim.loop.fs_unlink tmpname)
        arguments (table-concat
                    (if has-config [] default-configuration)
                    ["--show-column-numbers"
                     "--show-error-codes"
                     "--no-pretty"
                     "--shadow-file" current tmpname
                     current])
        command (python.module-command bufnr :mypy (unpack arguments))
        (ok res) (pcall
                   (fn []
                     (j.execute-command
                       bufnr command directory
                       (partial handle-result bufnr report-fn cleanup-fn))))]
    (when (not ok)
      (cleanup-fn)
      (error res))
    (LOG "Mypy Started" :bufnr bufnr :jobid res)
    res))


(fn cancel [bufnr jobid]
  (j.cancel jobid))


{: run 
 : cancel} 
