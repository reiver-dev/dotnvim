(fn t [str] (str:gsub " *([^ ]+) *" "%1"))

{:powerline

 {:slant
  {:ul (t "   ") :ur (t "   ") :ll (t "   ") :lr (t "   ")}
  :narrow "▊"}

 :diagnostic
 {:error "" :warn  "" :info  ""}

 :diff
 {:add "" :modify "" :remove ""}

 :diff-filled
 {:add "" :modify "柳" :remove " "}

 :vcs
 {:any "" :git ""}


 :mode
 {:c "🅒"
  :i "🅘"
  :n "🅝"
  :r "🅡"
  :s "🅢"
  :t "🅣"
  :v "🅥"
  :! ""
  ;; upper
  :C "🅒"
  :I "🅘"
  :N "🅝"
  :R "🅡"
  :S "🅢"
  :T "🅣"
  :V "🅥"
  :$ ""}

 :bullet "•"}
