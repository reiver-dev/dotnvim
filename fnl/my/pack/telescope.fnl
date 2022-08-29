(module my.pack.telescope)

(defn- make-path-display-shellslash []
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
                       (str-gsub path "\\" "/")
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


(defn configure []
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
      :borderchars border}})
  (when (string.match (. (vim.loop.os_uname) :sysname) "^Windows")
    (set config.defaults.path_display (make-path-display-shellslash)))
  (telescope.setup config)
  (_T :telescope :load_extension :my))


(defn buffers []
  (let [builtin (require :telescope.builtin)
        themes (require :telescope.themes)]
    (builtin.buffers (themes.get_ivy {:previewer false
                                      :results_title false}))))


(defn history []
  (let [builtin (require :telescope.builtin)
        themes (require :telescope.themes)]
    (builtin.oldfiles (themes.get_ivy {:previewer false
                                       :results_title false}))))


(defn setup []
  (configure)
  (vim.api.nvim_set_keymap
    :n "<C-x>b" "<cmd>lua _T('my.pack.telescope', 'buffers')<CR>" {:noremap true})
  (vim.api.nvim_set_keymap
    :n "<C-x>r" "<cmd>lua _T('my.pack.telescope', 'history')<CR>" {:noremap true}))
