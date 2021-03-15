(module my.fswalk
  {require {fs my.filesystem
            ps my.pathsep
            async my.async}})


(defn dirup [path]
  (let [sep fs.separator
        parent ps.parent
        iter (fn [state idx]
               (if (not idx)
                 state
                 (let [result (parent idx sep)]
                   (when (~= "" result)
                     result))))]
    (values iter path nil)))


(defn- directory? [path]
  (let [(res msg code) (vim.loop.fs_stat path)]
    (and res (= (. res :type) "directory"))))


(defn- assign [collection name value]
  (let [arr (. collection name)]
    (if arr
      (table.insert arr value)
      (tset collection name [value]))))


(defn gather [path files directories]
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


(def- astat
  (async.from-callback
    (fn [path continuation]
      (vim.loop.fs_stat
        path (fn [err stat rest]
               (if (not err)
                 (continuation path stat.type)
                 (continuation)))))))


(defn- async-gather-1 [path files directories]
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


(defn- async-gather-2 [path files directories]
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


(defn async-gather [path files directories]
  (async-gather-2 path files directories))
