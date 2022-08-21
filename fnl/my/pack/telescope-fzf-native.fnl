;;; Load telescope-fzf-native

(fn setup []
  (local telescope (require "telescope"))
  (telescope.load_extension :fzf))


{: setup}
