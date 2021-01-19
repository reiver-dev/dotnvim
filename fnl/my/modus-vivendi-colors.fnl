;;; modus-vivendi-colors

{:bg-main "#000000" :fg-main "#ffffff"
 :bg-alt "#181a20" :fg-alt "#a8a8a8"
 :bg-dim "#110b11" :fg-dim "#e0e6f0"
 ;; specifically for on/off states (e.g. `mode-line')
 ;;
 ;; must be combined with themselves
 :bg-active "#323232" :fg-active "#f4f4f4"
 :bg-inactive "#1e1e1e" :fg-inactive "#bfc0c4"
 ;; special base values, used only for cases where the above
 ;; fg-* or bg-* cannot or should not be used (to avoid confusion)
 ;; must be combined with: {fg,bg}-{main,alt,dim}
 :bg-special-cold "#203448" :fg-special-cold "#c6eaff"
 :bg-special-mild "#00322e" :fg-special-mild "#bfebe0"
 :bg-special-warm "#382f27" :fg-special-warm "#f8dec0"
 :bg-special-calm "#392a48" :fg-special-calm "#fbd6f4"
 ;; styles for the main constructs
 ;;
 ;; must be combined with: `bg-main', `bg-alt', `bg-dim'
 :red "#ff8059" :green "#44bc44"
 :yellow "#eecc00" :blue "#2fafff"
 :magenta "#feacd0" :cyan "#00d3d0"
 ;; styles for common, but still specialized constructs
 ;;
 ;; must be combined with: `bg-main', `bg-alt', `bg-dim'
 :red-alt "#f4923b" :green-alt "#80d200"
 :yellow-alt "#cfdf30" :blue-alt "#79a8ff"
 :magenta-alt "#f78fe7" :cyan-alt "#4ae8fc"
 ;; same purpose as above, just slight differences
 ;;
 ;; must be combined with: `bg-main', `bg-alt', `bg-dim'
 :red-alt-other "#ff9977" :green-alt-other "#00cd68"
 :yellow-alt-other "#f0ce43" :blue-alt-other "#00bcff"
 :magenta-alt-other "#b6a0ff" :cyan-alt-other "#6ae4b9"
 ;; styles for desaturated foreground text
 ;;
 ;; must be combined with: `bg-main', `bg-alt', `bg-dim'
 :red-faint "#ffa0a0" :green-faint "#88cf88"
 :yellow-faint "#d2b580" :blue-faint "#92baff"
 :magenta-faint "#e0b2d6" :cyan-faint "#a0bfdf"

 :red-alt-faint "#f5aa80" :green-alt-faint "#a8cf88"
 :yellow-alt-faint "#cabf77" :blue-alt-faint "#a4b0ff"
 :magenta-alt-faint "#ef9fe4" :cyan-alt-faint "#90c4ed"

 :red-alt-other-faint "#ff9fbf" :green-alt-other-faint "#88cfaf"
 :yellow-alt-other-faint "#d0ba95" :blue-alt-other-faint "#8fc5ff"
 :magenta-alt-other-faint "#d0b4ff" :cyan-alt-other-faint "#a4d0bb"
 ;; styles for elements that should be very subtle, yet accented
 ;;
 ;; must be combined with: `bg-main', `bg-alt', `bg-dim' or any of
 ;; the "nuanced" backgrounds
 :red-nuanced "#ffcccc" :green-nuanced "#b8e2b8"
 :yellow-nuanced "#dfdfb0" :blue-nuanced "#bfd9ff"
 :magenta-nuanced "#e5cfef" :cyan-nuanced "#a8e5e5"
 ;; styles for slightly accented background
 ;;
 ;; must be combined with any of the above foreground values
 :red-nuanced-bg "#2c0614" :green-nuanced-bg "#001904"
 :yellow-nuanced-bg "#221000" :blue-nuanced-bg "#0f0e39"
 :magenta-nuanced-bg "#230631" :cyan-nuanced-bg "#041529"
 ;; styles for elements that should draw attention to themselves
 ;;
 ;; must be combined with: `bg-main'
 :red-intense "#fb6859" :green-intense "#00fc50"
 :yellow-intense "#ffdd00" :blue-intense "#00a2ff"
 :magenta-intense "#ff8bd4" :cyan-intense "#30ffc0"
 ;; styles for background elements that should be visible yet
 ;; subtle
 ;;
 ;; must be combined with: `fg-dim'
 :red-subtle-bg "#762422" :green-subtle-bg "#2f4a00"
 :yellow-subtle-bg "#604200" :blue-subtle-bg "#10387c"
 :magenta-subtle-bg "#49366e" :cyan-subtle-bg "#00415e"
 ;; styles for background elements that should be visible and
 ;; distinguishable
 ;;
 ;; must be combined with: `fg-main'
 :red-intense-bg "#a4202a" :green-intense-bg "#006800"
 :yellow-intense-bg "#874900" :blue-intense-bg "#2a40b8"
 :magenta-intense-bg "#7042a2" :cyan-intense-bg "#005f88"
 ;; styles for refined contexts where both the foreground and the
 ;; background need to have the same/similar hue
 ;;
 ;; must be combined with themselves OR the foregrounds can be
 ;; combined with any of the base backgrounds
 :red-refine-bg "#77002a" :red-refine-fg "#ffb9ab"
 :green-refine-bg "#00422a" :green-refine-fg "#9ff0cf"
 :yellow-refine-bg "#693200" :yellow-refine-fg "#e2d980"
 :blue-refine-bg "#242679" :blue-refine-fg "#8ec6ff"
 :magenta-refine-bg "#71206a" :magenta-refine-fg "#ffcaf0"
 :cyan-refine-bg "#004065" :cyan-refine-fg "#8ae4f2"
 ;; styles that are meant exclusively for the mode line
 ;;
 ;; must be combined with: `bg-active', `bg-inactive'
 :red-active "#ffa7ba" :green-active "#70d73f"
 :yellow-active "#dbbe5f" :blue-active "#34cfff"
 :magenta-active "#d5b1ff" :cyan-active "#00d8b4"
 ;; styles that are meant exclusively for the fringes
 ;;
 ;; must be combined with `fg-main'
 :red-fringe-bg "#8f1f4b" :green-fringe-bg "#006700"
 :yellow-fringe-bg "#6f4f00" :blue-fringe-bg "#3f33af"
 :magenta-fringe-bg "#6f2f89" :cyan-fringe-bg "#004f8f"
 ;; styles reserved for specific faces
 ;;
 ;; `bg-hl-line' is between `bg-dim' and `bg-alt', so it should
 ;; work with all accents that cover those two, plus `bg-main'
 ;;
 ;; `bg-hl-alt' and `bg-hl-alt-intense' should only be used when no
 ;; other greyscale or fairly neutral background is available to
 ;; properly draw attention to a given construct
 ;;
 ;; `bg-header' is between `bg-active' and `bg-inactive', so it
 ;; can be combined with any of the "active" values, plus the
 ;; "special" and base foreground colors
 ;;
 ;; `bg-paren-match', `bg-paren-match-intense', `bg-region' and
 ;; `bg-tab-active' must be combined with `fg-main', while
 ;; `bg-tab-inactive' should be combined with `fg-dim'
 ;;
 ;; `bg-tab-bar' is only intended for the bar that holds the tabs and
 ;; can only be combined with `fg-main'
 ;;
 ;; `fg-tab-active' is meant to be combined with `bg-tab-active',
 ;; though only for styling special elements, such as underlining
 ;; the current tab
 ;;
 ;; `fg-escape-char-construct' and `fg-escape-char-backslash' can
 ;; be combined `bg-main', `bg-dim', `bg-alt'
 ;;
 ;; `fg-lang-error', `fg-lang-warning', `fg-lang-note' can be
 ;; combined with `bg-main', `bg-dim', `bg-alt'
 ;;
 ;; `fg-mark-sel', `fg-mark-del', `fg-mark-alt' can be combined
 ;; with `bg-main', `bg-dim', `bg-alt', `bg-hl-line'
 ;;
 ;; `fg-unfocused' must be combined with `fg-main'
 ;;
 ;; `fg-docstring', `fg-comment-yellow' can be `bg-main', `bg-dim',
 ;; `bg-alt'
 ;;
 ;; the window divider colors apply to faces with just an fg value
 ;;
 ;; all pairs are combinable with themselves
 :bg-hl-line "#151823"
 :bg-hl-line-intense "#2f2f2f"
 :bg-hl-alt "#181732"
 :bg-hl-alt-intense "#282e46"
 :bg-paren-match "#5f362f"
 :bg-paren-match-intense "#7416b5"
 :bg-region "#3c3c3c"
   
 :bg-tab-bar "#2c2c2c"
 :bg-tab-active "#0e0e0e"
 :bg-tab-inactive "#3d3d3d"
 :fg-tab-active "#5ac3cf"
   
 :fg-escape-char-construct "#e7a59a"
 :fg-escape-char-backslash "#abab00"
   
 :fg-lang-error "#ef8690"
 :fg-lang-warning "#b0aa00"
 :fg-lang-note "#9d9def"
   
 :fg-window-divider-inner "#646464"
 :fg-window-divider-outer "#969696"
   
 :fg-unfocused "#93959b"
   
 :fg-docstring "#b0d6f5"
 :fg-comment-yellow "#cab98f"
   
 :bg-header "#212121" :fg-header "#dddddd"
   
 :bg-whitespace "#170016" :fg-whitespace "#a4959f"
   
 :bg-diff-heading "#304466" :fg-diff-heading "#dadffe"
 :bg-diff-added "#0a280a" :fg-diff-added "#94ba94"
 :bg-diff-changed "#2a2000" :fg-diff-changed "#b0ba9f"
 :bg-diff-removed "#40160f" :fg-diff-removed "#c6adaa"
   
 :bg-diff-refine-added "#005a36" :fg-diff-refine-added "#e0f6e0"
 :bg-diff-refine-changed "#585800" :fg-diff-refine-changed "#ffffcc"
 :bg-diff-refine-removed "#852828" :fg-diff-refine-removed "#ffd9eb"
   
 :bg-diff-focus-added "#203d20" :fg-diff-focus-added "#b4ddb4"
 :bg-diff-focus-changed "#4a3a10" :fg-diff-focus-changed "#d0daaf"
 :bg-diff-focus-removed "#5e2526" :fg-diff-focus-removed "#eebdba"
   
 :bg-diff-neutral-0 "#575757" :fg-diff-neutral-0 "#fcfcfc"
 :bg-diff-neutral-1 "#454545" :fg-diff-neutral-1 "#dddddd"
 :bg-diff-neutral-2 "#313131" :fg-diff-neutral-2 "#bfbfbf"
   
 :bg-mark-sel "#002f2f" :fg-mark-sel "#60cfa2"
 :bg-mark-del "#5a0000" :fg-mark-del "#ff99aa"
 :bg-mark-alt "#3f2210" :fg-mark-alt "#f0aa20"}

;;; modus-vivendi-colors.fnl ends here
