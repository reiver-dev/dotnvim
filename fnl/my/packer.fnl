(module my.packer)

(defn- packer-config []
  (local pj (. (require "packer.util") :join_paths))
  {:display {:open_cmd "vertical botright new [packer]"}
   :compile_path (pj (vim.fn.stdpath :data) "packer_compiled.lua")
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
  (local opts (if (= (select :# ...) 1)
                ...
                (argpairs ...)))
  (tset opts :as opts.name)
  (tset opts 1 opts.url)
  (set opts.name nil)
  (set opts.url nil)
  (when opts.opt
    (set opts.config
         (if opts.config
           [opts.config #(_G.__after_load_hook $...)]
           [#(_G.__after_load_hook $...)])))
  opts)


(defn- make-packer-module [mod]
  (local mod (or mod (require "packer")))
  (local packer-use mod.use)
  (fn pkg [...] (packer-use (handle-packer-options ...)))
  {:packer mod :pkg pkg :use packer-use})


(defonce- package-hooks {})


(defn package-hook-set [name hook]
  (tset package-hooks name hook))


(defn hook [name hook]
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


(defn install [...]
  (exec :install ...))


(defn update [...]
  (exec :update ...))


(defn sync [...]
  (exec :sync ...))


(defn compile [...]
  (exec :compile ...))


(defn clean []
  (exec :clean))


(defn status []
  (exec :status))


(defn profile []
  (exec :profile_output))


(defn open-dir [plugin-names command-mods]
  (each [_ plugin-name (ipairs plugin-names)]
    (local plugin (. _G.packer_plugins plugin-name))
    (when plugin
      (vim.cmd (.. (or command-mods "") " split "
                   (vim.fn.fnameescape plugin.path))))))


(def- commands
  "
  command! PackerInit     lua _T('my.packer', 'init-packages')
  command! -nargs=+ -complete=customlist,v:lua.require'packer'.plugin_complete PackerOpen     lua _T('my.packer', 'open-dir', {<f-args>}, <q-mods>)
  command! -nargs=* -complete=customlist,v:lua.require'packer'.plugin_complete PackerInstall  lua require('my.packer').install(<f-args>)
  command! -nargs=* -complete=customlist,v:lua.require'packer'.plugin_complete PackerUpdate   lua require('my.packer').update(<f-args>)
  command! -nargs=* -complete=customlist,v:lua.require'packer'.plugin_complete PackerSync     lua require('my.packer').sync(<f-args>)
  command! PackerClean    lua _T('my.packer', 'clean')
  command! -nargs=* PackerCompile  lua _T('my.packer', 'compile', <q-args>)
  command! PackerStatus   lua _T('my.packer', 'status')
  command! PackerProfile  lua _T('my.packer', 'profile')
  ")


(defn setup []
  (vim.api.nvim_exec commands false))
