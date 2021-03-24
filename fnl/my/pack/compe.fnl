(module my.pack.compe
  {require {compe compe}})


(defn- make-set [...]
  (let [res {}]
    (each [_ arg (ipairs [...])]
      (tset res arg true))
    res))



(def- map-opts (make-set :noremap :silent :expr))
  

(defn- map [key action]
  (vim.api.nvim_set_keymap :i key action map-opts))
  

(defn setup []
  (compe.setup {:enabled true
                :source (make-set
                          :path
                          :buffer
                          :calc
                          :nvim_lsp
                          :nvim_lua
                          :snippets_nvim
                          :treesitter
                          :conjure)})
  (map "<C-x><C-x>" "compe#complete()")
  (map "<CR>" "compe#confirm('<CR>')")
  (map "<C-q>" "compe#close('<C-q>')"))

