(local fs (require "my.filesystem"))
(local ps (require "my.pathsep"))
(local async (require "my.async"))


(fn dirup [path]
  (let [sep fs.separator
        parent ps.parent
        iter (fn [state idx]
               (if (not idx)
                 state
                 (let [result (parent idx sep)]
                   (when (~= "" result)
                     result))))]
    (values iter path nil)))


(fn directory? [path]
  (let [(res msg code) (vim.loop.fs_stat path)]
    (and res (= (. res :type) "directory"))))


(fn assign [collection name value]
  (let [arr (. collection name)]
    (if arr
      (table.insert arr value)
      (tset collection name [value]))))


(fn gather [path files directories]
  (let [fe {}
        de {}]
    (when (and path (or files directories) (directory? path))
      (each [path (dirup path)]
        (when files
          (each [i f (ipairs files)]
            (let [loc (ps.join path f)]
              (when (fs.file? loc)
                (assign fe f loc)))))
        (when directories
          (each [i d (ipairs directories)]
            (let [loc (ps.join path d)]
              (when (fs.directory? loc)
                (assign de d loc)))))))
    (values fe de)))


(local astat
  (async.from-callback
    (fn [path continuation]
      (vim.loop.fs_stat
        path (fn [err stat rest]
               (if (not err)
                 (continuation path stat.type)
                 (continuation)))))
    1))


(fn async-gather-1 [path files directories]
  (let [found-dirs {}
        found-files {}]
    (when (and path (or files directories)
               (= (select 2 (async.wait (astat path))) "directory"))
      (let [paths []
            handles []]
        (each [base (dirup path)]
          (when files
            (each [_ fname (ipairs files)]
              (table.insert paths ["file" found-files fname base])
              (table.insert handles (astat (ps.join base fname)))))
          (when directories
            (each [_ dirname (ipairs directories)]
              (table.insert paths ["directory" found-dirs dirname base])
              (table.insert handles (astat (ps.join base dirname))))))
        (let [stats (async.wait (async.gather handles))]
          (when stats
            (each [i [oldpath filetype] (pairs stats)]
              (when filetype
                (let [[kind collection base path] (. paths i)]
                  (assign collection base path))))))))
    (values found-files found-dirs)))


(fn async-gather-2 [path files directories]
  (let [found-dirs {}
        found-files {}]
    (when (and path (or files directories)
               (= (select 2 (async.wait (astat path))) "directory"))
      (let [paths []
            handles []]
        (each [base (dirup path)]
          (when files
            (each [_ fname (ipairs files)]
              (table.insert paths ["file" found-files fname base])
              (table.insert handles (astat (ps.join base fname)))))
          (when directories
            (each [_ dirname (ipairs directories)]
              (table.insert paths ["directory" found-dirs dirname base])
              (table.insert handles (astat (ps.join base dirname))))))
        (each [i oldpath filetype (async.iter handles)]
          (when filetype
            (let [[kind collection base path] (. paths i)]
              (assign collection base path))))))
    (values found-files found-dirs)))


(fn collect-entry-count [query]
  (if (= nil query) 0
    (do
      (var count 0)
      (each [_mode entries (pairs query)]
        (set count (+ count (length entries))))
      count)))


(fn default-arr [collection key]
  (var value (. collection key))
  (when (= value nil)
    (set value [])
    (tset collection key value))
  value)


(fn default-map [collection key]
  (var value (. collection key))
  (when (= value nil)
    (set value {})
    (tset collection key value))
  value)


(fn on-entry [result finalizer mode base name err stat]
  (when (and (= err nil) (not= 0 (bit.band mode stat.mode)))
    (local per-mode (default-map result mode))
    (local per-entry (default-arr per-mode name))
    (table.insert per-entry base))
  (finalizer result))


(fn collect-gather-query [paths query callback]
  (local uv vim.loop)
  (local join ps.join)
  (local result {})

  (var entry-count 0)
  (each [mode entries (pairs query)]
    (tset result mode {})
    (set entry-count (+ entry-count (length entries))))

  (local base-count (length paths))

  (var total-count (* base-count entry-count))

  (fn finalizer [value]
    (set total-count (- total-count 1))
    (when (= total-count 0)
      (callback true value)))

  (local on-entry on-entry)

  (each [_ path (ipairs paths)]
    (each [mode entries (pairs query)]
      (local mode-result (. result mode))
      (each [_ name (ipairs entries)]
        (local handle
          (uv.fs_stat (join path name)
                      (partial on-entry result finalizer mode path name)))))))


(fn async-gather-simple [path files directories callback]
  (local query {0x8000 files 0x4000 directories})
  (local count (collect-entry-count query))
  (if (= count 0) (let [as (vim.loop.new_async (fn [] (callback {})))]
                    (as:send))
    (vim.loop.fs_stat
      path
      (fn [err stat]
        (if
          (not= nil err)
          (callback false err)
          (not= 0 (bit.band stat.mode 0x4000))
          (let [paths (icollect [base (dirup path)] base)]
            (collect-gather-query paths query callback)))))))


(fn async-gather [path files directories]
  (async-gather-2 path files directories))


{: dirup 
 : gather 
 : async-gather-simple 
 : async-gather} 

