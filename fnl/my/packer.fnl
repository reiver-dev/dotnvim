(module my.packer)

(defn- packer-config []
  (let [join (. (require "packer.util") :join_paths)
        iswin (= (. (vim.loop.os_uname) :sysname) "Windows_NT")
        root (if iswin
               (join (vim.fn.stdpath "config") "pack")
               (join (vim.fn.stdpath "data") "site" "pack"))]
    {:package_root root
     :disable_commands true}))


(defn init-packages []
  (let [packer (require "packer")
        spec {}]
    (tset spec 1 (fn [...] (_T :my.packages :setup ...)))
    (tset spec :config (packer-config))
    (packer.startup spec)))


(defn- gather-managed-plugins [plugins ...]
  (let [managed []
        direct []]
    (for [n 1 (select :# ...)]
      (let [name (select n ...)
            plugin (. plugins name)]
        (if plugin
          (when (not plugin.loaded)
            (table.insert managed name))
          (table.insert direct name))))
    (values managed direct)))


(defn- load-packages-direct [names]
  (when (and names (next names))
    (let [loaded (loaded-packages)]
      (each [_ name (ipairs names)]
        (when (not (. name loaded))
          (vim.cmd (.. "packadd " name)))))))


(defn- loaded-packages []
  (let [rtp vim.o.runtimepath
        pattern "/pack/[^/]+/opt/([^/,]+)"
        loaded {}]
    (each [name (rtp:gmatch pattern)]
      (tset loaded name true))
    loaded))


(defn load-package [...]
  (when (< 0 (select :# ...))
    (var plugins _G.packer_plugins)
    (if (and plugins (next plugins))
      (let [(managed direct) (gather-managed-plugins plugins ...)]
        ;; Directly load unmanaged
        (load-packages-direct direct)
        ;; Load managed plugins
        ((require "packer.load") managed {} plugins))
      ;; No packer, directly load everything
      (load-packages-direct [...]))))


(defn package-complete [args line pos]
  (let [result []
        packer-plugins _G.packer_plugins]
    (when packer-plugins
      (each [name plugin (pairs packer-plugins)]
        (when (not plugin.loaded)
          (table.insert result name))))
    (table.concat result "\n")))


(def- commands
  "
  function! PackageToLoadComplete(arg, line, pos)
    return v:lua._T('my.packer', 'package-complete', a:arg, a:line, a:pos)
  endfunction
  command! PackerInit     lua _T('my.packer', 'init-packages')
  command! PackerInstall  lua require('packer').install()
  command! PackerUpdate   lua require('packer').update()
  command! PackerSync     lua require('packer').sync()
  command! PackerClean    lua require('packer').clean()
  command! PackerCompile  lua require('packer').compile()
  command! -nargs=+ -complete=custom,PackageToLoadComplete PackerLoad lua _T('my.packer', 'load-package', <f-args>)
  ")
  

(defn setup []
  (vim.api.nvim_exec commands false))
