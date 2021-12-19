;;; Tree-sitter parsers for neorg

(fn setup []
  (local pcfg (_T :nvim-treesitter.parsers :get_parser_configs))

  (set pcfg.norg
       {:install_info
        {:url "https://github.com/nvim-neorg/tree-sitter-norg"
         :files ["src/parser.c" "src/scanner.cc"]
         :branch "main"}})

  (set pcfg.norg_meta
       {:install_info
        {:url "https://github.com/nvim-neorg/tree-sitter-norg-meta"
         :files ["src/parser.c"]
         :branch "main"}})

  (set pcfg.norg_table
       {:install_info
        {:url "https://github.com/nvim-neorg/tree-sitter-norg-table"
         :files ["src/parser.c"]
         :branch "main"}}))


{: setup}
