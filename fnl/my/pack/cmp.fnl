(local cmp (require :cmp))

(local sources
  [{:name :nvim_lsp}
   {:name :nvim_lua}
   {:name :conjure}
   {:name :neorg}
   {:name :path}
   {:name :buffer}])


(fn make-cache-mt [func]
  {:__index (fn [tbl key]
              (local val (func key))
              (tset tbl key val)
              val)})

(local left-brace "[")
(local right-brace "]")

(fn format-source-name [str]
  (var str (tostring str))
  (when (= "nvim_" (string.sub str 1 5))
    (set str (string.sub str 6)))
  (.. left-brace
      (string.upper (string.sub str 1 1))
      (string.sub str 2)
      right-brace))


(local source-mapping
  (setmetatable {:nvim_lsp (.. left-brace "LSP" right-brace)}
                (make-cache-mt format-source-name)))


(fn format-kind-name [str]
  (local preset (. (or package.loaded.lspkind (require "lspkind"))
                   :presets :default))
  (.. (or (. preset str) " ") " " str))


(local kind-mapping
  (setmetatable {:TypeParameter "[T] TypeParameter"}
                (make-cache-mt format-kind-name)))


(fn format [entry item]
  (set item.kind (. kind-mapping item.kind))
  (set item.menu (.. (or item.menu "")
                     (. source-mapping entry.source.name)))
  item)


(local mapping
  {:<C-p> (cmp.mapping.select_prev_item)
   :<C-n> (cmp.mapping.select_next_item)
   :<C-d> (cmp.mapping.scroll_docs -4)
   :<C-f> (cmp.mapping.scroll_docs 4)
   :<C-x><C-x> (cmp.mapping.complete)
   :<C-e> (cmp.mapping.abort)
   :<C-y> (cmp.mapping.confirm {:select false})
   :<CR> (cmp.mapping.confirm
           {:behavior cmp.ConfirmBehavior.Replace
            :select false})})


(fn setup []
  (local format-entry
    (match (pcall require :lspkind)
      (true lspkind) (lspkind.cmp_format
                       {:with_text true
                        :maxwidth 50
                        :menu source-mapping})
      _ nil))
  (cmp.setup {:mapping mapping
              :completion {:autocomplete false}
              :formatting {:format format-entry}
              :experimental {:ghost_text true}
              :sources sources})
  (when _G.packer_plugins.neorg
    (_T :my.pack.neorg.cmp :setup)))


{: setup}
