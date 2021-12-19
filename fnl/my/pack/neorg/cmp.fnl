;;; Lazy-load neorg completion

(fn load-cmp [neorg]
  (neorg.modules.load_module :core.norg.completion nil
                             {:engine "nvim-cmp"}))


(fn setup []
  (when _G.packer_plugins :neorg
    (_T :my.pack.neorg.autoload :run
        :cmp load-cmp)))


{: setup}
