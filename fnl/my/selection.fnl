(local point (require "my.point"))


(fn lines-trim-region [lines col-begin col-end]
  (local len (length lines))
  (local str-sub string.sub)
  (local max math.max)
  (if
    (< 1 len)
    (do
      (tset lines 1 (str-sub (. lines 1) (max 1 col-begin)))
      (tset lines len (str-sub (. lines len) 1 col-end)))
    (< 0 len)
    (tset lines 1 (str-sub (. lines 1) (max 1 col-begin) col-end)))
  lines)


(fn lines-trim-block [lines col-begin col-end]
  (local str-sub string.sub)
  (local max math.max)
  (for [i 1 (length lines)]
    (tset lines i (str-sub (. lines i) (max 1 col-begin) col-end)))
  lines)


(fn lines-max-length [lines]
  (local max math.max)
  (var maxlen 0)
  (for [i 1 (length lines)]
    (set maxlen (max maxlen (length (. lines i)))))
  maxlen)


(fn string-indent [line]
  (or (string.find line "[^%s]") 0))


(fn lines-dedent [lines]
  (local min math.min)
  (local sub string.sub)
  (var min-indent 2147483647)
  (for [i 1 (length lines)]
    (local line (. lines i))
    (local indent (string-indent line))
    (when (not= 0 indent)
      (set min-indent (min min-indent indent))))
  (when (and (< 1 min-indent 2147483647))
    (for [i 1 (length lines)]
      (tset lines i (sub (. lines i) min-indent))))
  lines)


(fn lines-dedent-nonempty [lines]
  (local str-sub string.sub)
  (local min math.min)
  (local nlines [])
  (var min-indent 0)
  (for [i 1 (length lines)]
    (local line (. lines 1))
    (local indent (string-indent line))
    (when (not= nil indent)
      (set min-indent (min min-indent indent))
      (tset nlines (+ 1 (length nlines)) line)))
  (when (< 1 min-indent)
    (for [i 1 (length nlines)]
      (tset lines i (str-sub (. lines i) min-indent))))
  nlines)


(fn lines-reindent [lines]
  (local str-sub string.sub)
  (local str-rep string.rep)
  (local base-indent (string-indent (. lines 1)))
  (when (< 1 base-indent)
    (tset lines 1 (str-sub (. lines 1) base-indent))
    (for [i 2 (length lines)]
      (local line (. lines i))
      (local indent (string-indent line))
      (if (or (<= base-indent indent) (= indent 0))
        (tset lines i (str-sub line base-indent))
        (tset lines i (.. (str-rep " " (+ 1 (- base-indent indent)))
                          line)))))
  lines)


(fn lines-extend-column [lines col]
  (local len (length lines))
  (if (= len 0) col
    (< (length (. lines 1)) col) 2147483647
    col))


(local visual-register :v)


(fn copy-last-visual-select [register]
  (vim.api.nvim_exec (string.format "silent normal! gv\"%.1sy" register) false)
  (vim.fn.getreginfo register))


(fn get-normal-visual-lines [register]
  (local old-regdata (vim.fn.getreginfo register))
  (local (ok data) (pcall copy-last-visual-select register))
  (vim.fn.setreg register old-regdata)
  (when (not ok)
    (error data))
  (values data.regcontents data.regtype))


(fn normal-selection []
  (local (lines regtype) (get-normal-visual-lines visual-register))
  (if (= 86 (string.byte regtype 1))
    (lines-dedent lines)
    lines))


(fn range-selection [line1 line2]
  (vim.api.nvim_buf_get_lines 0 (- line1 1) line2 false))


(fn selection [modenum]
  (match (or modenum (string.byte (. (vim.api.nvim_get_mode) :mode) 1))
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


{: lines-trim-region 
 : lines-trim-block 
 : lines-max-length 
 : string-indent 
 : lines-dedent 
 : lines-dedent-nonempty 
 : lines-reindent 
 : lines-extend-column 
 : get-normal-visual-lines 
 : normal-selection 
 : range-selection 
 : visual-register
 : selection} 
