(local nvim (require :aniseed.nvim))


(fn map-ft [ft mode from to]
  (nvim.ex.autocmd
   :FileType ft
   (.. mode :map)
   (.. :<localleader> from)
   to))


(provide :map-ft map-ft)
