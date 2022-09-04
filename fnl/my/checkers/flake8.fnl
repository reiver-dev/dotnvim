(local j (require "my.check.job"))
(local python (require "my.lang.python"))

(local Error vim.diagnostic.severity.ERROR)
(local Warning vim.diagnostic.severity.WARN)
(local Information vim.diagnostic.severity.INFO)
(local Hint vim.diagnostic.severity.HINT)


(local line-pattern
  "stdin:([^:]+):([^:]+): ([^ ]+) (.*)")


(local severity-patterns
  {"^redefinition" Warning
   ".*unused.*" Warning
   "used$" Warning
   "^E9.*"  Error
   "^F8[23].*" Error
   "^D.*" Information
   "^N.*" Information
   "^[EW][0-9]+" Information})


(fn convert-severity-1 [code iter state pattern severity]
  (if pattern
    (if (string.match code pattern)
      severity
      (convert-severity-1 code iter state (iter state pattern)))
    Error))


(fn convert-severity [code]
  (let [(iter state idx) (pairs severity-patterns)]
    (convert-severity-1 code iter state (iter state idx))))


(fn parse-line [line]
  (let [(line col code msg) (string.match line line-pattern)]
    (when line
      (let [line (- (tonumber line) 1)
            col (- (tonumber col) 1)]
        {:source "flake8"
         :lnum line
         :end_lnum line
         :col col
         :end_col (+ col 1)
         :message msg
         :severity (convert-severity code)}))))


(fn parse-output [lines]
  (let [result []]
    (each [_ line (ipairs lines)]
      (let [entry (parse-line line)]
        (when entry
          (table.insert result entry))))
    result))


(fn run [bufnr report-fn]
  (let [res (j.execute-command
              bufnr (python.module-command bufnr "flake8" "-") nil
              (fn [jobid result]
                (LOG "Flake8 Finished" :jobid jobid :result result)
                (report-fn (parse-output result.stdout))))]
    (j.send-buffer res bufnr)
    res))


(fn cancel [bufnr state]
  (j.cancel state))


{: run 
 : cancel} 
