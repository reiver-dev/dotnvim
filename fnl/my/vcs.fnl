(module my.vcs
  {require {pkg bootstrap.pkgmanager
            path my.pathsep
            fs my.filesystem
            b my.bufreg}})


(defn- buffer [bufnr]
  (let [t (type bufnr)]
    (assert (or (= t :nil)
                (= t :number) (.. "BUFNR must be number, got " t))))
  (if (and bufnr (< 0 bufnr))
    bufnr
    (vim.api.nvim_get_current_buf)))


(defn- packages []
  (pkg.def
    {:name :signify
     :url "mhinz/vim-signify"}))


(def- trigger-list [:git :hg])
(def- triggers {:git [:project :triggers :dirs :.git]
                :hg [:project :triggers :dirs :.hg]})



(defn get-marker [bufnr]
  (var bufnr (buffer bufnr))
  (each [_ vcs (ipairs trigger-list)]
    (let [dirs (b.get-local bufnr (unpack (. triggers vcs)))]
      (when dirs
        (let [dir (. dirs 1)]
          (when dir
            (lua "return vcs,dir")))))))


(defn buffer-has-vcs [bufnr]
  (let [(vcs dir) (get-marker bufnr)]
    (and vcs dir)))


(defn- isws [val]
  (or
    ;; "\n"
    (= val 10)
    ;; " "
    (= val 32)))


(defn- strip [text]
  (when text (path.rtrim text #(isws ($1:byte $2)))))
                            

(defn- find-git-head [dir]
  (-> (path.join dir "HEAD")
      (fs.slurp)
      (string.match "ref: refs/heads/(.*)")
      (strip)))


(defn- find-hg-bookmark [dir]
  (-> (path.join dir "bookmarks.current")
      (fs.slurp)
      (strip)))


(defn- find-hg-branch [dir]
  (-> (path.join dir "branch")
      (fs.slurp)
      (strip)))


(defn- git-head [bufnr root]
  (let [known (b.get-local bufnr :vcs :git :head)]
    (if known
      known
      (let [head (find-git-head (path.join root ".git"))]
        (when head
          (b.set-local bufnr :vcs :git :head head)
          head)))))


(defn- hg-head [bufnr root]
  (let [known (b.get-local bufnr :vcs :hg :head)]
    (if known
      known
      (let [dir (path.join root ".hg")
            branch (find-hg-branch dir)
            bookmark (find-hg-bookmark dir)]
        (var head nil)
        (when branch
          (set head branch))
        (when bookmark
          (set head (if head (.. head "|" bookmark) bookmark)))
        (when head
          (let [info {:branch branch
                      :bookmark bookmark
                      :head head}]
            (b.set-local bufnr :vcs :hg info)
            head))))))



(defn find-head [bufnr]
  (var bufnr (buffer bufnr))
  (let [(vcs dir) (get-marker bufnr)]
    (when vcs
      (match vcs
        :git (.. "git:" (git-head bufnr dir))
        :hg (.. "hg:"  (hg-head bufnr dir))))))



(defn setup []
  (packages))

