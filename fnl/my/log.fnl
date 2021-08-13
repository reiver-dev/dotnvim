(local module-name ...)

(local state (let [m (. package.loaded module-name)]
               (or (and (= (type m) "table") m._state) {})))

(local inspect vim.inspect)
(local str-format string.format)
(local str-gsub string.gsub)
(local join table.concat)

(local get-current-bufnr vim.api.nvim_get_current_buf)
(local in-fast-event vim.in_fast_event)
(local format-date os.date)

(local fs_write vim.loop.fs_write)
(local fs_open vim.loop.fs_open)
(local fs_close vim.loop.fs_close)
(local gettimeofday vim.loop.gettimeofday)
(local floor math.floor)


(fn current-buffer []
  (if (in-fast-event)
    0
    (get-current-bufnr)))


(fn make-timestamp-string []
  (let [(sec usec) (gettimeofday)]
    (.. (format-date "%Y-%m-%d %H:%M:%S" sec)
        (str-format ".%06d" usec))))


(fn format-message [now bufnr message data]
  (if (not= data nil)
    (str-format "[I %s B:%d] %s\n    %s\n"
                   now bufnr message (str-gsub (join data "\n")
                                               "\n"
                                               "\n    "))
    (str-format "[I %s B:%d] %s\n" now bufnr message)))


(fn format-data-entry [key val]
  (.. (tostring key) ": " (inspect val)))


(fn format-data-key-only [key]
  (.. (tostring key) ": <NOTSET>"))


(fn gather-data-1 [tbl n i key val ...]
  (tset tbl i (format-data-entry key val))
  (when (not= i n)
    (gather-data-1 tbl n (+ i 1) ...)))


(fn gather-data [...]
  (local num-entries (select :# ...))
  (when (not= 0 num-entries)
    (let [full-pairs (floor (/ num-entries 2))
          has-tail (% num-entries 2)
          tbl {}]
      (when (not= full-pairs 0)
        (gather-data-1 tbl full-pairs 1 ...))
      (when (not= has-tail 0)
        (tset tbl (+ full-pairs 1)
              (format-data-key-only (select num-entries ...))))
      tbl)))


(fn log [message ...]
  (let [now (make-timestamp-string)
        file (. state :file)]
    (when file
      (fs_write
        file
        (format-message now (current-buffer) message (gather-data ...))
        0))))


(fn setup []
  (let [file (. state :file)]
    (when file (fs_close file)))
  (let [p (vim.fn.stdpath "cache")
        l (.. p "/" "my.log")]
    (vim.fn.mkdir p "p")
    (tset state :path l)
    (tset state :file (fs_open l "a+" 438))))


(tset _G :log log)

{:_state state
 : setup
 : log}
