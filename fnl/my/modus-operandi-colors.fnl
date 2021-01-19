;;; modus-operandi-colors

{:bg-main "#ffffff" :fg-main "#000000"
 :bg-alt "#f0f0f0" :fg-alt "#505050"
 :bg-dim "#f8f8f8" :fg-dim "#282828"
 ;; specifically for on/off states (e.g. `mode-line')
 ;;
 ;; must be combined with themselves
 :bg-active "#d7d7d7" :fg-active "#0a0a0a"
 :bg-inactive "#efefef" :fg-inactive "#404148"
 ;; special base values, used only for cases where the above
 ;; fg-* or bg-* cannot or should not be used (to avoid confusion)
 ;; must be combined with: {fg,bg}-{main,alt,dim}
 :bg-special-cold "#dde3f4" :fg-special-cold "#093060"
 :bg-special-mild "#c4ede0" :fg-special-mild "#184034"
 :bg-special-warm "#f0e0d4" :fg-special-warm "#5d3026"
 :bg-special-calm "#f8ddea" :fg-special-calm "#61284f"
 ;; styles for the main constructs
 ;;
 ;; must be combined with: `bg-main', `bg-alt', `bg-dim'
 :red "#a60000" :green "#005e00"
 :yellow "#813e00" :blue "#0031a9"
 :magenta "#721045" :cyan "#00538b"
 ;; styles for common, but still specialized constructs
 ;;
 ;; must be combined with: `bg-main', `bg-alt', `bg-dim'
 :red-alt "#972500" :green-alt "#315b00"
 :yellow-alt "#70480f" :blue-alt "#2544bb"
 :magenta-alt "#8f0075" :cyan-alt "#30517f"
 ;; same purpose as above, just slight differences
 ;;
 ;; must be combined with: `bg-main', `bg-alt', `bg-dim'
 :red-alt-other "#a0132f" :green-alt-other "#145c33"
 :yellow-alt-other "#863927" :blue-alt-other "#0000c0"
 :magenta-alt-other "#5317ac" :cyan-alt-other "#005a5f"
 ;; styles for desaturated foreground text
 ;;
 ;; must be combined with: `bg-main', `bg-alt', `bg-dim'
 :red-faint "#7f1010" :green-faint "#104410"
 :yellow-faint "#5f4400" :blue-faint "#002f88"
 :magenta-faint "#752f50" :cyan-faint "#12506f"

 :red-alt-faint "#702f00" :green-alt-faint "#30440f"
 :yellow-alt-faint "#5d5000" :blue-alt-faint "#003f78"
 :magenta-alt-faint "#702565" :cyan-alt-faint "#354f6f"

 :red-alt-other-faint "#7f002f" :green-alt-other-faint "#0f443f"
 :yellow-alt-other-faint "#5e3a20" :blue-alt-other-faint "#1f0f6f"
 :magenta-alt-other-faint "#5f3f7f" :cyan-alt-other-faint "#2e584f"
 ;; styles for elements that should be very subtle, yet accented
 ;;
 ;; must be combined with: `bg-main', `bg-alt', `bg-dim' or any of
 ;; the "nuanced" backgrounds
 :red-nuanced "#5f0000" :green-nuanced "#004000"
 :yellow-nuanced "#3f3000" :blue-nuanced "#201f55"
 :magenta-nuanced "#541f4f" :cyan-nuanced "#0f3360"
 ;; styles for slightly accented background
 ;;
 ;; must be combined with any of the above foreground values
 :red-nuanced-bg "#fff1f0" :green-nuanced-bg "#ecf7ed"
 :yellow-nuanced-bg "#fff3da" :blue-nuanced-bg "#f3f3ff"
 :magenta-nuanced-bg "#fdf0ff" :cyan-nuanced-bg "#ebf6fa"
 ;; styles for elements that should draw attention to themselves
 ;;
 ;; must be combined with: `bg-main'
 :red-intense "#b60000" :green-intense "#006800"
 :yellow-intense "#904200" :blue-intense "#1111ee"
 :magenta-intense "#7000e0" :cyan-intense "#205b93"
 ;; styles for background elements that should be visible yet
 ;; subtle
 ;;
 ;; must be combined with: `fg-dim'
 :red-subtle-bg "#f2b0a2" :green-subtle-bg "#aecf90"
 :yellow-subtle-bg "#e4c340" :blue-subtle-bg "#b5d0ff"
 :magenta-subtle-bg "#f0d3ff" :cyan-subtle-bg "#c0efff"
 ;; styles for background elements that should be visible and
 ;; distinguishable
 ;;
 ;; must be combined with: `fg-main'
 :red-intense-bg "#ff8892" :green-intense-bg "#5ada88"
 :yellow-intense-bg "#f5df23" :blue-intense-bg "#6aaeff"
 :magenta-intense-bg "#d5baff" :cyan-intense-bg "#42cbd4"
 ;; styles for refined contexts where both the foreground and the
 ;; background need to have the same/similar hue
 ;;
 ;; must be combined with themselves OR the foregrounds can be
 ;; combined with any of the base backgrounds
 :red-refine-bg "#ffcccc" :red-refine-fg "#780000"
 :green-refine-bg "#aceaac" :green-refine-fg "#004c00"
 :yellow-refine-bg "#fff29a" :yellow-refine-fg "#604000"
 :blue-refine-bg "#8ac7ff" :blue-refine-fg "#002288"
 :magenta-refine-bg "#ffccff" :magenta-refine-fg "#770077"
 :cyan-refine-bg "#8eecf4" :cyan-refine-fg "#004850"
 ;; styles that are meant exclusively for the mode line
 ;;
 ;; must be combined with: `bg-active', `bg-inactive'
 :red-active "#8a0000" :green-active "#004c2e"
 :yellow-active "#702d1f" :blue-active "#0030b4"
 :magenta-active "#5c2092" :cyan-active "#003f8a"
 ;; styles that are meant exclusively for the fringes
 ;;
 ;; must be combined with `fg-main'
 :red-fringe-bg "#f08290" :green-fringe-bg "#62c86a"
 :yellow-fringe-bg "#dbba3f" :blue-fringe-bg "#82afff"
 :magenta-fringe-bg "#e0a3ff" :cyan-fringe-bg "#2fcddf"
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
 ;; `fg-docstring', `fg-comment-yellow' can be combined with
 ;; `bg-main', `bg-dim', `bg-alt'
 ;;
 ;; the window divider colors apply to faces with just an fg value
 ;;
 ;; all pairs are combinable with themselves
 :bg-hl-line "#f2eff3"
 :bg-hl-line-intense "#e0e0e0"
 :bg-hl-alt "#fbeee0"
 :bg-hl-alt-intense "#e8dfd1"
 :bg-paren-match "#e0af82"
 :bg-paren-match-intense "#c488ff"
 :bg-region "#bcbcbc"

 :bg-tab-bar "#d5d5d5"
 :bg-tab-active "#f6f6f6"
 :bg-tab-inactive "#bdbdbd"
 :fg-tab-active "#30169e"

 :fg-escape-char-construct "#8b1030"
 :fg-escape-char-backslash "#654d0f"

 :fg-lang-error "#9f004f"
 :fg-lang-warning "#604f0f"
 :fg-lang-note "#4040ae"

 :fg-window-divider-inner "#888888"
 :fg-window-divider-outer "#585858"

 :fg-unfocused "#56576d"

 :fg-docstring "#2a486a"
 :fg-comment-yellow "#5f4400"

 :bg-header "#e5e5e5" :fg-header "#2a2a2a"

 :bg-whitespace "#fff8fc" :fg-whitespace "#645060"

 :bg-diff-heading "#b7c2dd" :fg-diff-heading "#043355"
 :bg-diff-added "#d4fad4" :fg-diff-added "#004500"
 :bg-diff-changed "#fcefcf" :fg-diff-changed "#524200"
 :bg-diff-removed "#ffe8ef" :fg-diff-removed "#691616"

 :bg-diff-refine-added "#94cf94" :fg-diff-refine-added "#002a00"
 :bg-diff-refine-changed "#cccf8f" :fg-diff-refine-changed "#302010"
 :bg-diff-refine-removed "#daa2b0" :fg-diff-refine-removed "#400000"

 :bg-diff-focus-added "#bbeabb" :fg-diff-focus-added "#002c00"
 :bg-diff-focus-changed "#ecdfbf" :fg-diff-focus-changed "#392900"
 :bg-diff-focus-removed "#efcbcf" :fg-diff-focus-removed "#4a0000"

 :bg-diff-neutral-0 "#979797" :fg-diff-neutral-0 "#040404"
 :bg-diff-neutral-1 "#b0b0b0" :fg-diff-neutral-1 "#252525"
 :bg-diff-neutral-2 "#cccccc" :fg-diff-neutral-2 "#3a3a3a"

 :bg-mark-sel "#a0f0cf" :fg-mark-sel "#005040"
 :bg-mark-del "#ffccbb" :fg-mark-del "#840040"
 :bg-mark-alt "#f5d88f" :fg-mark-alt "#782900"}
 
 


;;; modus-operandi-colors.fnl ends here
