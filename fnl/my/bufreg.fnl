;;; Trampouline to bufreg plugin

(local {: getlocal : setlocal : updlocal} (require "bufreg"))

(fn set-local [bufnr ...]
  "Associate value with BUFNR buffer state."
  (setlocal bufnr ...))


(fn get-local [bufnr ...]
  "Get associated value from BUFNR buffer state."
  (getlocal bufnr ...))


(fn update-local [bufnr ...]
  "Update associated value from BUFNR buffer state."
  (updlocal bufnr ...))


(fn setup [])


{: setup
 : set-local
 : get-local
 : update-local}
