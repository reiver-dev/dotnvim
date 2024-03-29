(var gl (require "galaxyline"))
(var condition (require "galaxyline.condition"))
(var icons (require "my.ui.icons"))


(fn merge [...]
  (local result {})
  (for [i 1 (select :# ...)]
    (each [k v (pairs (select i ...))]
      (tset result k v)))
  result)


(fn tbl-reset [tbl new]
  (each [k v (pairs tbl)]
    (tset tbl k nil))
  (each [k v (pairs new)]
    (tset tbl k v)))


(fn tohex [tbl]
  (collect [k v (pairs tbl)]
    (if (and (= (type k) :string)
             (= (type v) :number))
      (values k (string.format "#%.6x" v))
      (values k v))))


(fn argpairs-1 [tbl n k v ...]
  (when k
    (tset tbl k v))
  (if (< 0 n)
    (argpairs-1 tbl (- n 2) ...)
    tbl))


(fn argpairs [...]
  (argpairs-1 {} (- (select :# ...) 2) ...))


(fn section [tbl name ...]
  (table.insert tbl {name (argpairs ...)}))


(fn pt [fun arg0]
  (fn [...] (fun arg0 ...)))


(fn get-local [...]
  (_T :my.bufreg :get-local 0 ...))


(fn join-entries [tbl]
  (let [res  []]
    (each [k v (pairs tbl)]
      (table.insert res (string.format "%s=%s" k v)))
    res))


(fn hi [name ...]
  (vim.cmd (string.format "hi %s %s" name (-> (argpairs ...)
                                              (join-entries)
                                              (table.concat " ")))))


(set gl.short_line_list [:NvimTree :vista :dbui])



(local base-colors-default
  {:bg-base "#202328"
   :fg-base "#bbc2cf"
   :yellow "#ECBE7B"
   :cyan "#008080"
   :darkblue "#081633"
   :green "#98be65"
   :orange "#FF8800"
   :violet "#a9a1e1"
   :magenta "#c678dd"
   :blue "#51afef"
   :red "#ec5f67"})


(local base-colors-dark
  {:yellow :Yellow
   :cyan :DarkCyan
   :darkblue :LightBlue
   :green base-colors-default.green
   :orange :Orange
   :violet base-colors-default.violet
   :magenta base-colors-default.magenta
   :blue :LightBlue
   :red base-colors-default.red})


(local base-colors-light
  {:yellow :Brown
   :cyan :DarkCyan
   :darkblue :DarkBlue
   :green :DarkGreen
   :orange :Brown
   :violet :Purple
   :magenta :DarkMagenta
   :blue :SlateBlue
   :red base-colors-default.red})


(var color-statusline {})
(var color-statusline-inactive {})
(var color-vertsplit {})
(var base-colors {})


(local base-color-access
  (collect [k v (pairs base-colors-default)]
    (values k (fn [] (or (. base-colors k)
                         (. base-colors-default k))))))


(local colors
  (merge {:bg (fn [] (or color-statusline.background
                         base-colors-default.bg-base))
          :fg (fn [] (or color-statusline.foreground
                         base-colors-default.fg-base))}
         base-color-access))


(local colors-inactive
  (merge {:bg (fn [] (or color-statusline-inactive.background
                         base-colors-default.bg-base))
          :fg (fn [] (or color-statusline-inactive.foreground
                         base-colors-default.fb-base))}
         base-color-access))


(fn on-colorscheme []
  (tbl-reset color-statusline
       (tohex (vim.api.nvim_get_hl_by_name :StatusLine true)))
  (tbl-reset color-statusline-inactive
       (tohex (vim.api.nvim_get_hl_by_name :StatusLineNC true)))
  (tbl-reset color-vertsplit
       (tohex (vim.api.nvim_get_hl_by_name :VertSplit true)))
  (tbl-reset base-colors (if (= vim.o.background :light)
                           base-colors-light
                           base-colors-dark)))


(on-colorscheme)


(vim.cmd
  "augroup galaxyline_colorscheme
  autocmd!
  autocmd ColorScheme * lua _T('my.ui.galaxyline', 'on-colorscheme')
  augroup END")


(set gl.section.left [])
(set gl.section.right [])
(set gl.section.short_line_left [])
(set gl.section.short_line_right [])

(local left (pt section gl.section.left))
(local right (pt section gl.section.right))
(local left-inactive (pt section gl.section.short_line_left))
(local right-inactive (pt section gl.section.short_line_right))


(local mode-colors {:N base-colors-default.red
                    :V base-colors-default.blue
                    :I base-colors-default.green
                    :C base-colors-default.magenta
                    :P base-colors-default.cyan
                    :S base-colors-default.orange
                    :R base-colors-default.violet
                    :T base-colors-default.blue
                    :$ base-colors-default.red})


(left :ViMode
      :provider (fn []
                  (let [mode (_T :my.ui.mode :resolve-current)]
                    (hi :GalaxyViMode
                        :guifg (colors.bg-base)
                        :guibg (. mode-colors mode)
                        :gui "bold")
                    (string.format "  %s " (. icons.mode mode))))
      :separator " "
      :separator_highlight [:NONE colors.bg])


;; File information

(left :FileSize
      :provider "FileSize"
      :condition condition.buffer_not_empty
      :highlight [colors.fg colors.bg])


(left :FileIcon
      :provider "FileIcon"
      :highlight [(. (require "galaxyline.providers.fileinfo") :get_file_icon_color)
                  colors.bg :NONE])



(fn file-name []
  (string.format
    "%s%s %s"
    (if (or (= :help vim.bo.filetype) vim.bo.readonly) " " "")
    (let [name (vim.fn.expand "%:t")] (if (not= name "") name "[No Name]"))
    (if (and vim.bo.modifiable vim.bo.modified) " " "  ")))


(left :FileName
      :provider file-name
      :highlight [colors.magenta colors.bg :bold])


;; File position

(left :LineColumn
      :provider #(string.format "%5s:%-3s" (vim.fn.line ".") (vim.fn.col "."))
      :separator " "
      :separator_highlight [:NONE colors.bg]
      :highlight [colors.fg colors.bg])


(left :PerCent
      :provider #(let [current (vim.fn.line ".")
                       total (vim.fn.line "$")]
                   (match current
                     1 " Top "
                     total " Bot "
                     _ (string.format " %2.0f%% " (math.modf (* (/ current total) 100)))))
      :separator "%<"
      :separator_highlight [:NONE colors.bg]
      :highlight [colors.fg colors.bg :NONE])


(local HOME
  (let [sep (if (= "\\" (package.config:sub 1 1))
              "[\\/]+" "/+")]
    (.. "^" (-> vim.env.HOME
                vim.pesc
                (string.gsub sep sep)))))


(fn replacehome [path]
  (string.gsub path HOME "~"))


(left :Directory
      :provider #(match (get-local :directory)
                   nil ""
                   dir (replacehome dir))
      :separator " "
      :separator_highlight [:NONE colors.bg]
      :highlight [colors.fg colors.bg :nocombine])


;; Diagnostics

(fn extract-diagnostics [kind]
  (let [bufnr (vim.api.nvim_get_current_buf)
        diags (vim.diagnostic.get bufnr {:severity kind})
        dcount (length diags)]
    (when (< 0 dcount)
      (string.format "%d " dcount))))


(left :DiagnosticError
      :provider (pt extract-diagnostics "ERROR")
      :condition condition.hide_in_width
      :icon " "
      :highlight [colors.red colors.bg])

(left :DiagnosticWarning
      :provider (pt extract-diagnostics "WARN")
      :condition condition.hide_in_width
      :icon " "
      :highlight [colors.yellow colors.bg])

(left :DiagnosticHint
      :provider (pt extract-diagnostics "HINT")
      :condition condition.hide_in_width
      :icon " "
      :highlight [colors.cyan colors.bg])

(left :DiagnosticInformation
      :provider (pt extract-diagnostics "INFO")
      :condition condition.hide_in_width
      :icon " "
      :highlight [colors.blue colors.bg])


(right :Project
       :provider #(match (get-local :project :root)
                    nil ""
                    dir (replacehome dir))
       :separator " "
       :separator_highlight [:NONE colors.bg]
       :highlight [colors.fg colors.bg])


(fn lsp-clients []
  (local client-names
    (icollect [_ client (ipairs (vim.lsp.buf_get_clients 0))]
      (string.format "%s(%d)" client.name client.id)))
  (if (< 0 (length client-names))
    (string.format "LSP[%s]" (table.concat client-names ", "))
    "LSP[∅]"))


(right :LspClients
       :provider lsp-clients
       :condition condition.hide_in_width
       :separator " "
       :separator_highlight [colors.fb colors.bg]
       :highlight [colors.fg colors.bg])


;; File text info
(local file-format-icon
  {:unix "\\n"
   :dos "\\r\\n"
   :mac "\\r"})


(fn file-format []
  (local enc vim.bo.fileencoding)
  (local ff vim.bo.fileformat)
  (string.format
    "[%s%s]" enc
    (if (not= enc :binary) (.. " " (or (. file-format-icon ff) ff) ""))))


(right :FileFormat
       :provider file-format
       :condition condition.hide_in_width
       :separator " "
       :separator_highlight [:NONE colors.bg]
       :highlight [colors.green colors.bg :bold])


;; VCS data

(right :VcsHead
       :provider (fn [] (.. (_T :my.vcs :find-head 0) " "))
       :condition #(_T :my.vcs :buffer-has-vcs 0)
       :icon " "
       :separator "  "
       :separator_highlight [:NONE colors.bg]
       :highlight [colors.violet colors.bg :bold])

(right :DiffAdd
       :provider "DiffAdd"
       :condition condition.hide_in_width
       :icon " "
       :highlight [colors.green colors.bg])

(right :DiffModified
       :provider "DiffModified"
       :condition condition.hide_in_width
       :icon " "
       :highlight [colors.orange colors.bg])

(right :DiffRemove
       :provider "DiffRemove"
       :condition condition.hide_in_width
       :icon " "
       :highlight [colors.red colors.bg])


(left-inactive :SBufferType
               :provider "FileTypeName"
               :separator " "
               :separator_highlight [:NONE colors-inactive.bg]
               :highlight [colors-inactive.blue colors-inactive.bg :bold])

(left-inactive :SFileName
               :provider "SFileName"
               :separator " %<"
               :separator_highlight [:NONE colors-inactive.bg]
               :condition condition.buffer_not_empty
               :highlight [colors-inactive.fg colors-inactive.bg :bold])

(left-inactive :SDirectory
               :provider #(let [dir (get-local :directory)]
                            (if dir (vim.fn.fnamemodify dir ":~") ""))
               :condition condition.buffer_not_empty
               :highlight [colors-inactive.fg colors-inactive.bg :none])

(right-inactive :SBufferIcon
                :provider "BufferIcon"
                :highlight [colors-inactive.fg colors-inactive.bg])


{: on-colorscheme}

;;; galaxyline.fnl ends here
