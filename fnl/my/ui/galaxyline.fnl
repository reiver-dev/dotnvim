(var gl (require "galaxyline"))
(var colors (. (require "galaxyline.theme") :default))
(var condition (require "galaxyline.condition"))

(set gl.short_line_list [:NvimTree :vista :dbui])


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


(fn get-local [bufnr ...]
  (_T :my.bufreg :get-local bufnr ...))


(set gl.section.left [])
(set gl.section.right [])
(set gl.section.short_line_left [])
(set gl.section.short_line_right [])

(local left (pt section gl.section.left))
(local right (pt section gl.section.right))
(local left-inactive (pt section gl.section.short_line_left))
(local right-inactive (pt section gl.section.short_line_right))


(left :RainbowRed
      :provider (fn [] "▊ ")
      :highlight [colors.blue colors.bg])


(local mode-colors {:N colors.red
                    :V colors.blue
                    :I colors.green
                    :C colors.magenta
                    :P colors.cyan
                    :S colors.orange
                    :R colors.violet
                    :T colors.blue
                    :$ colors.red})

(left :ViMode
      :provider (fn []
                  (let [mode (_T :my.ui.mode :resolve-current)]
                    (vim.api.nvim_command (.. "hi GalaxyViMode guifg=" (. mode-colors mode)))
                    (string.format "[%s] " mode)))
      :highlight [colors.red colors.bg :bold])
        

;; File information

(left :FileSize
      :provider "FileSize"
      :condition condition.buffer_not_empty
      :highlight [colors.fg colors.bg])


(left :FileIcon
      :provider "FileIcon"
      :condition condition.buffer_not_empty
      :highlight [(. (require "galaxyline.provider_fileinfo") :get_file_icon_color)
                  colors.bg])

(left :FileName
      :provider "FileName"
      :condition condition.buffer_not_empty
      :highlight [colors.magenta colors.bg :bold])


;; File position

(left :LineColumn
      :provider #(string.format
                   "%5s:%-3s" (vim.fn.line ".") (vim.fn.col ".")) 
      :separator " "
      :separator_highlight [:NONE colors.bg]
      :highlight [colors.fg colors.bg])
                  
      
(left :PerCent
      :provider #(let [current (vim.fn.line ".")
                       total (vim.fn.line "$")]
                   (if (= current 1)
                     " Top "
                     (if (= current total)
                       " Bot "
                       (string.format
                         " %2.0f%% " (math.modf (* (/ current total) 100))))))
      :separator " "
      :separator_highlight [:NONE colors.bg]
      :highlight [colors.fg colors.bg :bold])


(left :Directory
      :provider #(let [dir (get-local 0 :directory)]
                   (if dir (vim.fn.fnamemodify dir ":~") ""))
      :separator " "
      :separator_highlight [:NONE colors.bg]
      :highlight [colors.fg colors.bg :bold])


;; Diagnostics

(fn extract-diagnostics [kind]
  (let [lsp vim.lsp
        bufnr (vim.api.nvim_get_current_buf)
        clients (lsp.buf_get_clients bufnr)
        enabled (or (get-local 0 :enabled-checkers) [])]
    (if (or (next clients) (next enabled))
      (do
        (var count 0)
        (each [_ client (ipairs clients)]
          (set count (+ count (lsp.diagnostic.get_count bufnr kind client.id))))
        (each [_ client-id (pairs enabled)]
          (set count (+ count (lsp.diagnostic.get_count bufnr kind client-id))))
        (if (< 0 count)
          (string.format "%d " count)
          ""))
      ""))) 


(left :DiagnosticError
      :provider (pt extract-diagnostics "Error")
      :icon "  "
      :highlight [colors.red colors.bg])

(left :DiagnosticWarning
      :provider (pt extract-diagnostics "Warning")
      :icon "   "
      :highlight [colors.yellow colors.bg])

(left :DiagnosticHint
      :provider (pt extract-diagnostics "Hint")
      :icon "  "
      :highlight [colors.cyan colors.bg])

(left :DiagnosticInformation
      :provider (pt extract-diagnostics "Information")
      :icon "  "
      :highlight [colors.blue colors.bg])



(right :Project
      :provider #(let [dir (get-local 0 :project :root)]
                   (if dir (vim.fn.fnamemodify dir ":~") ""))
      :separator " "
      :separator_highlight [:NONE colors.bg]
      :highlight [colors.fg colors.bg :bold])


;; File text info

(right :FileEncode
       :provider "FileEncode"
       :separator " "
       :separator_highlight [:NONE colors.bg]
       :highlight [colors.green colors.bg :bold])

(right :FileFormat
       :provider "FileFormat"
       :separator " "
       :separator_highlight [:NONE colors.bg]
       :highlight [colors.green colors.bg :bold])


;; VCS data

(right :VcsIcon
       :provider (fn [] "  ")
       :condition #(_T :my.vcs :buffer-has-vcs 0)
       :separator " "
       :separator_highlight [:NONE colors.bg]
       :highlight [colors.violet colors.bg :bold])

(right :VcsHead
       :provider (fn [] (.. (_T :my.vcs :find-head 0) " "))
       :condition #(_T :my.vcs :buffer-has-vcs 0)
       :separator " "
       :separator_highlight [:NONE colors.bg]
       :highlight [colors.violet colors.bg :bold])

(right :DiffAdd
       :provider "DiffAdd"
       :condtion condition.hide_in_width
       :icon "   "
       :highlight [colors.green colors.bg])

(right :DiffModified
       :provider "DiffModified"
       :condtion condition.hide_in_width
       :icon " 柳"
       :highlight [colors.orange colors.bg])
       
(right :DiffRemove
       :provider "DiffRemove"
       :condtion condition.hide_in_width
       :icon "  "
       :highlight [colors.red colors.bg])

(right :RainbowBlue
       :provider (fn [] "  ▊")
       :highlight [colors.blue colors.bg])


(left-inactive :BufferType
               :provider "FileTypeName"
               :separator " "
               :separator_highlight [:NONE colors.bg]
               :highlight [colors.blue colors.bg :bold])

(left-inactive :SFileName
               :provider "SFileName"
               :condition condition.buffer_not_empty
               :highlight [colors.fg colors.bg :bold])

(right-inactive :BufferIcon
                :provider "BufferIcon"
                :highlight [colors.fg colors.bg])
               
