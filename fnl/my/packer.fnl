(module my.packer)

(defn- packer-config []
  {:display {:open_cmd "vertical botright new [packer]"}
   :disable_commands true})


(defn init-packages []
  (let [packer (require "packer")]
    (packer.init (packer-config))
    (packer.reset)
    (_T :my.packages :configure-packages)))


(defn- exec [name]
  (RELOAD "my.packages")
  (init-packages)
  (_T :packer name))


(defn install []
  (exec :install))


(defn update []
  (exec :update))


(defn sync []
  (exec :sync))


(defn compile []
  (exec :compile))


(defn clean []
  (exec :clean))


(defn status []
  (exec :status))


(def- commands
  "
  command! PackerInit     lua _T('my.packer', 'init-packages')
  command! PackerInstall  lua _T('my.packer', 'install')
  command! PackerUpdate   lua _T('my.packer', 'update')
  command! PackerSync     lua _T('my.packer', 'sync')
  command! PackerClean    lua _T('my.packer', 'clean')
  command! PackerCompile  lua _T('my.packer', 'compile')
  command! PackerStatus   lua _T('my.packer', 'status')
  ")
  

(defn setup []
  (vim.api.nvim_exec commands false))
