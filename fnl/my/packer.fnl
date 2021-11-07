(module my.packer)

(defn- packer-config []
  {:display {:open_cmd "vertical botright new [packer]"}
   :disable_commands true})


(defn- argpairs-1 [tbl n k v ...]
  (when k
    (tset tbl k v))
  (if (< 0 n)
    (argpairs-1 tbl (- n 2) ...)
    tbl))


(defn- argpairs [...]
  (argpairs-1 {} (- (select :# ...) 2) ...))


(defn- handle-packer-options [...]
  (local opts (argpairs ...))
  (tset opts :as opts.name)
  (tset opts 1 opts.url)
  (set opts.name nil)
  (set opts.url nil)
  opts)


(defn- make-packer-module [mod]
  (local mod (or mod (require "packer")))
  (local packer-use mod.use)
  (fn pkg [...] (packer-use (handle-packer-options ...)))
  {:packer mod :pkg pkg :use packer-use})


(defonce- package-hooks {})


(defn package-hook-set [name hook]
  (tset package-hooks name hook))


(defn- package-hook-execute [packer]
  (each [name hook (pairs package-hooks)]
    (hook (make-packer-module packer))))


(defn init-packages []
  (let [packer (require "packer")]
    (packer.init (packer-config))
    (packer.reset)
    (package-hook-execute packer)))


(defn- configure-default-packages [mod]
  ((require :my.packages) mod))


(defn- exec [name ...]
  (RELOAD "my.packages")
  (package-hook-set :my.packages configure-default-packages)
  (init-packages)
  (_T :packer name ...))


(defn install []
  (exec :install))


(defn update []
  (exec :update))


(defn sync []
  (exec :sync))


(defn compile [...]
  (exec :compile ...))


(defn clean []
  (exec :clean))


(defn status []
  (exec :status))


(defn profile []
  (exec :profile_output))


(def- commands
  "
  command! PackerInit     lua _T('my.packer', 'init-packages')
  command! PackerInstall  lua _T('my.packer', 'install')
  command! PackerUpdate   lua _T('my.packer', 'update')
  command! PackerSync     lua _T('my.packer', 'sync')
  command! PackerClean    lua _T('my.packer', 'clean')
  command! -nargs=* PackerCompile  lua _T('my.packer', 'compile', <q-args>)
  command! PackerStatus   lua _T('my.packer', 'status')
  command! PackerProfile  lua _T('my.packer', 'profile')
  ")


(defn setup []
  (vim.api.nvim_exec commands false))
