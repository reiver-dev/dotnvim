(module my.pack.cmp
  {require {cmp cmp}})


(def- sources
  [{:name :buffer}
   {:name :nvim_lsp}
   {:name :conjure}
   {:name :path}
   {:name :nvim_lua}])


(defn- make-cache-mt [func]
  {:__index (fn [tbl key]
              (local val (func key))
              (tset tbl key val)
              val)})

(def- left-brace "[")
(def- right-brace "]")

(defn- format-source-name [str]
  (var str (tostring str))
  (when (= "nvim_" (string.sub str 1 5))
    (set str (string.sub str 6)))
  (.. left-brace
      (string.upper (string.sub str 1 1))
      (string.sub str 2)
      right-brace))


(def- source-mapping
  (setmetatable {:nvim_lsp (.. left-brace "LSP" right-brace)}
                (make-cache-mt format-source-name)))


(defn- format-kind-name [str]
  (local preset (. (or package.loaded.lspkind (require "lspkind"))
                   :presets :default))
  (.. (or (. preset str) " ") " " str))


(def- kind-mapping
  (setmetatable {:TypeParameter "[T] TypeParameter"}
                (make-cache-mt format-kind-name)))


(defn- format [entry item]
  (set item.kind (. kind-mapping item.kind))
  (set item.menu (.. (or item.menu "")
                     (. source-mapping entry.source.name)))
  item)


(def- mapping
  {:<C-p> (cmp.mapping.select_prev_item)
   :<C-n> (cmp.mapping.select_next_item)
   :<C-d> (cmp.mapping.scroll_docs -4)
   :<C-f> (cmp.mapping.scroll_docs 4)
   :<C-x><C-x> (cmp.mapping.complete)
   :<C-e> (cmp.mapping.close)
   :<CR> (cmp.mapping.confirm {:behavior cmp.ConfirmBehavior.Insert :select true})})


(def- border
  (let [r []]
    (for [i 1 8]
      (tset r i [" " :FloatShadow]))
    r))


(defn setup []
  (cmp.setup {:mapping mapping
              :formatting {:format format}
              :documentation {:border border}
              :sources sources}))

