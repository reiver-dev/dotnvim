(module my.checkers.flake8
  {require {j my.check.job
            python my.lang.python}})


(def- Error vim.diagnostic.severity.ERROR)
(def- Warning vim.diagnostic.severity.WARN)
(def- Information vim.diagnostic.severity.INFO)
(def- Hint vim.diagnostic.severity.HINT)


(def- line-pattern
  "stdin:([^:]+):([^:]+): ([^ ]+) (.*)")


(def- severity-patterns
  {"^redefinition" Warning
   ".*unused.*" Warning
   "used$" Warning
   "^E9.*"  Error
   "^F8[23].*" Error
   "^D.*" Information
   "^N.*" Information
   "^[EW][0-9]+" Information})


(defn- convert-severity-1 [code iter state pattern severity]
  (if pattern
    (if (string.match code pattern)
      severity
      (convert-severity-1 code iter state (iter state pattern)))
    Error))


(defn- convert-severity [code]
  (let [(iter state idx) (pairs severity-patterns)]
    (convert-severity-1 code iter state (iter state idx))))


(defn- parse-line [line]
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


(defn- parse-output [lines]
  (let [result []]
    (each [_ line (ipairs lines)]
      (let [entry (parse-line line)]
        (when entry
          (table.insert result entry))))
    result))


(defn run [bufnr report-fn]
  (let [res (j.execute-command
              bufnr (python.module-command bufnr "flake8" "-") nil
              (fn [jobid result]
                (log "Flake8 Finished" :jobid jobid :result result)
                (report-fn (parse-output result.stdout))))]
    (j.send-buffer res bufnr)
    res))


(defn cancel [bufnr state]
  (j.cancel state))
