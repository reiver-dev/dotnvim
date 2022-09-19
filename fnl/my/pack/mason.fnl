(fn install-root-dir []
  (.. _G.STDPATH_RAW.data (_G.package.config:sub 1 1) "mason"))


(fn setup []
  (_T :mason :setup {:install_root_dir (install-root-dir)}))

{: setup}
