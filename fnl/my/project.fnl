(module my.project
  {require {util bootstrap.util}})


(defn- git-root []
  (string.gsub (vim.fn.system "git rev-parse --show-toplevel") "\n" ""))


(defn- set-project-root [path]
  (set vim.b.projectile path)
  (set vim.b.asyncrun_root path))


(defn- get-project-root []
  vim.b.projectile)


(def- command
  "command! ProjectileFiles lua _trampouline('my.project', 'files')")

(vim.cmd command)


(defn find-project-root []
  (git-root))
  

(defn project-root []
  (let [root (get-project-root)]
    (if root
      root
      (let [nroot (find-project-root)]
        (when nroot
          (set-project-root nroot)
          nroot)))))


(defn files []
  (vim.cmd (.. "Files " (project-root))))
