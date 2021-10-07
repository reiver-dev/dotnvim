(module my.selection
  {require {point my.point}})


(defn lines-trim-region [lines col-begin col-end]
  (local len (length lines))
  (if
    (< 1 len)
    (do
      (tset lines 1 (string.sub (. lines 1) (math.max 1 col-begin)))
      (tset lines len (string.sub (. lines len) 1 col-end)))
    (< 0 len)
    (tset lines 1 (string.sub (. lines 1) (math.max 1 col-begin) col-end)))
  lines)


(defn lines-trim-block [lines col-begin col-end]
  (for [i 1 (length lines)]
    (tset lines i (string.sub (. lines i) (math.max 1 col-begin))))
  lines)


(defn lines-max-length [lines]
  (var maxlen 0)
  (for [i 1 (length lines)]
    (set maxlen (math.max maxlen (length (. lines i)))))
  maxlen)


(defn string-indent [line]
  (or (string.find line "[^%s]") 0))


(defn lines-dedent [lines]
  (var min-indent 2147483647)
  (for [i 1 (length lines)]
    (local line (. lines 1))
    (local indent (string-indent line))
    (when (not= 0 indent)
      (set min-indent (math.min min-indent indent))))
  (when (< 1 min-indent)
    (for [i 1 (length lines)]
      (tset lines i (string.sub (. lines i) min-indent))))
  lines)


(defn lines-dedent-nonempty [lines]
  (local nlines [])
  (var min-indent 0)
  (for [i 1 (length lines)]
    (local line (. lines 1))
    (local indent (string-indent line))
    (when (not= nil indent)
      (set min-indent (math.min min-indent indent))
      (tset nlines (+ 1 (length nlines)) line)))
  (when (< 1 min-indent)
    (for [i 1 (length nlines)]
      (tset lines i (string.sub (. lines i) min-indent))))
  nlines)


(defn lines-reindent [lines]
  (local base-indent (string-indent (. lines 1)))
  (when (< 1 base-indent)
    (tset lines 1 (string.sub (. lines 1) base-indent))
    (for [i 2 (length lines)]
      (local line (. lines i))
      (local indent (string-indent line))
      (if (or (<= base-indent indent) (= indent 0))
        (tset lines i (string.sub line base-indent))
        (tset lines i (.. (string.rep " " (+ 1 (- base-indent indent)))
                          line)))))
  lines)


(defn lines-extend-column [lines col]
  (local len (length lines))
  (if (= len 0) col
    (< (length (. lines 1)) col) 2147483647
    col))


(def visual-register :v)


(defn- copy-last-visual-select [register]
  (vim.cmd (string.format "silent normal! gv\"%.1sy" register))
  (local reginfo (vim.fn.getreginfo register))
  (values reginfo.regcontents reginfo.regtype))


(defn- with-register-finally [regname regdata status ...]
  (vim.fn.setreg regname regdata)
  (when (not status)
    (error ...))
  (values ...))


(defn- with-register [?register func]
  (local regname (string.sub (or ?register visual-register) 1 1))
  (local regdata (vim.fn.getreginfo regname))
  (with-register-finally
    regname regdata (xpcall #(func regname) debug.traceback)))


(defn get-normal-visual-lines [register]
  (with-register register copy-last-visual-select))


(defn normal-selection []
  (local (lines regtype) (get-normal-visual-lines))
  (if (= 86 (string.byte regtype 1))
    (lines-dedent lines)
    lines))


(defn range-selection [line1 line2]
  (vim.api.nvim_buf_get_lines 0 (- line1 1) line2 false))


(defn visual-selection []
  (let [(bl bc el ec) (point.visual-point)
        lines (vim.api.nvim_buf_get_lines 0 (- bl 1) el false)
        curswant (. (vim.fn.winsaveview) :curswant)]
    (match (string.byte (vim.fn.visualmode) 1)
      ;; v region
      118 (lines-trim-region lines (+ bc 1) (+ ec 1))
      ;; V line
      86 (lines-dedent lines)
      ;; ^V block
      22 (lines-trim-block lines (+ bc 1) (math.max (+ ec 1) curswant))
      ;; What?
      _ lines)))


(defn selection []
  (match (string.byte (. (vim.api.nvim_get_mode) :mode) 1)
    ;; normal
    110 (normal-selection)
    ;; v region
    118 (let [(bl bc el ec) (point.visual-point)
              lines (vim.api.nvim_buf_get_lines 0 (- bl 1) el false)]
          (lines-trim-region lines (+ bc 1) (+ ec 1)))
    ;; V line
    86 (let [(bl bc el ec) (point.visual-point)
             lines (vim.api.nvim_buf_get_lines 0 (- bl 1) el false)]
          (lines-dedent lines))
    ;; ^V block
    22 (let [(bl bc el ec) (point.visual-point)
             lines (vim.api.nvim_buf_get_lines 0 (- bl 1) el false)
             curswant (. (vim.fn.winsaveview) :curswant)]
         (lines-trim-block lines (+ bc 1) (math.max (+ ec 1) curswant)))))
