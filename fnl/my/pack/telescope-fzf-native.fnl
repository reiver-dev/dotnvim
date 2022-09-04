;;; Load telescope-fzf-native


(fn shell-join [cmds]
  (table.concat
    (icollect [_ subcommand (ipairs cmds)]
      (table.concat subcommand " ")) " && "))
  

(fn start [command cwd]
  (let [bufnr (vim.api.nvim_create_buf true true)
        opts {:cwd cwd
              :on_exit (fn [jobid data event]
                         (vim.notify (string.format "Telescope FZF build exited: %d" data)))}]
    (vim.cmd (string.format ":vertical botright sbuffer %d" bufnr))
    (vim.fn.termopen command opts)))


(fn keep-window-finalize [oldwin ok ...]
  (vim.api.nvim_set_current_win oldwin)
  (when (not ok) (error ...))
  ...)


(fn keep-window [func ...]
  (let [curwin (vim.api.nvim_get_current_win)]
    (keep-window-finalize curwin (pcall func ...))))


(local build-command
  (if
    (= 1 (vim.fn.has :win32))
    [["cmake -S. -Bbuild"]
     ["cmake --build build --config Release"]
     ["cmake --install build --prefix build"]]

    (= 1 (vim.fn.executable :cmake))
    [["cmake" "-S." "-Bbuild" "-DCMAKE_BUILD_TYPE=Release"]
     ["cmake" "--build" "build"]
     ["cmake" "--install" "build" "--prefix" "build"]]

    [["make"]]))


(fn compile-library [plugin]
  (vim.notify "Building telescope fzf lib")
  (let [plugin (or plugin (?. _G :packer_plugins :telescope-fzf-native))
        path (when plugin (or plugin.path plugin.install_path))]
    (keep-window start (shell-join build-command) path)))


(fn setup []
  (local telescope (require "telescope"))
  (telescope.load_extension :fzf))


{: compile-library
 : setup}
