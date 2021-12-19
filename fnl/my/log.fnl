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


(fn gather-data-1 [tbl step nargs key val ...]
  (if
    (< 2 nargs) (do
                  (tset tbl step (format-data-entry key val))
                  (gather-data-1 tbl (+ step 1) (- nargs 2) ...))
    (= 2 nargs) (do
                 (tset tbl step (format-data-entry key val))
                 tbl)
    (= 1 nargs) (do
                  (tset tbl step (format-data-key-only key val))
                  tbl)
    tbl))


(fn gather-data [...]
  (local num-entries (select :# ...))
  (when (not= num-entries 0)
    (local tbl {})
    (gather-data-1 tbl 1 num-entries ...)))


(fn log [message ...]
  (let [now (make-timestamp-string)
        file (. state :file)]
    (when file
      (fs_write
        file
        (format-message now (current-buffer) message (gather-data ...))
        0))))


(fn setup []
  (tset _G :LOG log)
  (let [file (. state :file)]
    (when file (fs_close file)))
  (let [p (vim.fn.stdpath "cache")
        l (.. p "/" "my.log")]
    (vim.fn.mkdir p "p")
    (tset state :path l)
    (tset state :file (fs_open l "a+" 438))))


{:_state state
 : setup
 : log}
