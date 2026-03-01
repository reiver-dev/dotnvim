;;; Load telescope-fzf-native


(fn shell-join [cmds]
  (table.concat
    (icollect [_ subcommand (ipairs cmds)]
      (table.concat subcommand " ")) " && "))
  

(local build-command
  (if
    (= 1 (vim.fn.has :win32))
    [["cmake -S. -Bbuild"]
     ["cmake --build build --config Release"]
     ["cmake --install build --prefix build"]]

    (= 1 (vim.fn.executable :cmake))
    [["cmake" "-S." "-Bbuild" "-DCMAKE_BUILD_TYPE=Release"]
     ["cmake" "--build" "build"]]

    [["make"]]))


(fn compile-library [plugin]
  (local name (if plugin plugin.spec.name "UNDEFINED"))
  (local path (if plugin plugin.path "UNDEFINED"))
  (vim.notify (string.format "Building `%s` in `%s`" name path))
  (_T :my.pack :start name (shell-join build-command) path))


(fn setup []
  (local telescope (require "telescope"))
  (telescope.load_extension :fzf))


{: compile-library
 : setup}
