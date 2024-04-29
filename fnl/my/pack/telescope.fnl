;; Telescope main configuration

(fn make-path-display-shellslash []
  (local base-func (. (require :telescope.utils) :transform_path))
  (local P (require "plenary.path"))
  (local base-opts {:path_display {}})
  (local str-gsub string.gsub)
  (local str-sub string.sub)
  (local home (-> vim.env.USERPROFILE
                  (str-gsub  "[\\\\/]" "\\")
                  (str-gsub "\\+$" "")))
  (local cut-front (fn [s prefix]
                     (local plen (length prefix))
                     (if (= (string.sub s 1 plen) prefix)
                       (.. "~" (str-sub s (+ 1 plen)))
                       s)))
  (local normalize (fn [path]
                     (if _G.SHELLSLASH
                       (let [res (str-gsub path "\\" "/")] res)
                       path)))
  (fn [opts path]
    (if (and path (not= path "") (not= path "[No Name]"))
      (let [winpath (str-gsub path "[\\\\/]+" "\\")
            p (P.new winpath)
            cwd (or opts.cwd (vim.loop.cwd))
            rel-cwd (P.make_relative p cwd)
            rel-home (cut-front winpath home)]
        (normalize
          (if (<= (length rel-cwd) (length rel-home))
            rel-cwd
            rel-home)))
      path)))


(local extension-mods 
  {:file_browser #(_T :my.pack.telescope-file-browser :config)})


(fn extension-config-loader []
  (setmetatable
    {} {:__index (fn [t key]
                   (local (ok config) (pcall (. extension-mods key)))
                   (when (and ok (not= config nil))
                     (tset t key config)
                     config))}))


(fn configure []
  (local telescope (require :telescope))
  (local actions (require :telescope.actions))
  (local border ["─" "│" "─" "│" "┌" "┐" "┘" "└"])
  (local config
    {:defaults
     {:mappings
      {:n {:<C-g> actions.close
           :<C-n> actions.move_selection_next
           :<C-p> actions.move_selection_previous
           :q actions.close}
       :i {:<C-g> actions.close
           :<C-c> actions.close
           :<C-f> false
           :<C-d> false
           :<C-u> false
           :<C-e> false
           :<C-h> false
           :<M-u> actions.preview_scrolling_up
           :<M-d> actions.preview_scrolling_down}}
      :prompt_prefix "❯ "
      :selection_caret " "
      :sorting_strategy :ascending
      :results_title false
      :layout_config {:prompt_position :top}
      :borderchars border}
     :extensions (extension-config-loader)})
  (when (string.match (. (vim.loop.os_uname) :sysname) "^Windows")
    (set config.defaults.path_display (make-path-display-shellslash)))
  (telescope.setup config)
  (_T :telescope :load_extension :my))


(fn files [opts]
  (local builtin (require :telescope.builtin))
  (local topts {:search_file opts.args
                :hidden opts.bang
                :no_ignore opts.bang})
  (builtin.find_files topts))


(fn setup []
  (configure))


{: setup}
