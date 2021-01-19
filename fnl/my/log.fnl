(module my.log)


(defonce- state {})


(def- inspect
  (let [(ok view) (pcall (fn [] (require "aniseed.deps.fennelview")))]
    (if ok 
      view
      vim.inspect)))


(defn- format [bufnr message data]
  (let [now (os.date "%Y-%m-%d %H:%M:%S")]
   (if (and data (. data 1))
    (string.format "[I %s B:%d] %s\n    %s\n"
                   now bufnr message (string.gsub (table.concat data "\n")
                                                  "\n" "\n    "))
    (string.format "[I %s B:%d] %s\n"
                   now bufnr message))))

    
(defn- gather-data-1 [t n key val ...]
  (when (> n 0) 
    (when key
      (table.insert
       t
       (.. (tostring key) ": " (inspect val))))
    (gather-data-1 t (- n 1) ...)))


(defn- gather-data [...]
  (let [n (/ (select :# ...) 2)
        t {}]
    (gather-data-1 t n ...)
    t))


(defn- current-buffer []
  (if (vim.in_fast_event)
    0
    (vim.api.nvim_get_current_buf)))
  


(defn log [message ...]
  (let [file (. state :file)]
    (when file
      (vim.loop.fs_write
        file
        (format (current-buffer) message (gather-data ...))
        0))))


(tset _G :log log)


(defn setup []
  (let [file (. state :file)]
      (when file (vim.loop.fs_close file)))
  (let [p (vim.fn.stdpath "data")
        l (.. p "/" "my.log")]
    (vim.fn.mkdir p "p")
    (tset state :path l)
    (tset state :file (vim.loop.fs_open l "a+" 438))))
