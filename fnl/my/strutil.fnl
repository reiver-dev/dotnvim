(local find string.find)
(local sub string.sub)
(local byte string.byte)
(local format string.format)

(local fmod math.fmod)


(fn divmod [a b]
  (let [r (fmod a b)]
    (values (/ (- a r) b) r)))


(fn expandvar [text exp]
  (var result [])
  (var at 1)
  (var len (length text))
  (var num 1)

  (var b 0)
  (var e 0)

  (var expr-begin 0)
  (var expr-end 0)

  (var prefix 1)
  (var limit 10)

  (while (<= at len)
    (set (b e) (find text "%$+[A-Za-z0-9_{]" at))

    (if b
      ;; Maybe env var
      (let [(count remainder) (divmod (- e b) 2)]
        ;; Maybe ballanced braces
        (if (= 123 (byte text e))
          (let [(expr-begin expr-end) (find text "^%b{}" e)]
            (when (not expr-begin)
              (error (.. "Non-balanced paren at pos " e)))

            (tset result num (sub text prefix (+ (- b 1) count)))
            (set num (+ num 1))

            (if (not= 0 remainder)
              (let [value (exp (sub text (+ expr-begin 1) (- expr-end 1)))]
                (when (not= value nil)
                  (tset result num value)
                  (set num (+ num 1))))
              (do
                (tset result num (sub text expr-begin expr-end))
                (set num (+ num 1))))

            (set prefix (+ expr-end 1))
            (set at (+ expr-end 1)))

          ;; Plain var
          (let [(expr-begin expr-end) (find text "^[A-Za-z0-9_]+" e)]
            (when (not expr-begin)
              (error (.. "Invalid state at pos " e)))

            (tset result num (sub text prefix (+ (- b 1) count)))
            (set num (+ num 1))

            (if (not= 0 remainder)
              (let [value (exp (sub text expr-begin expr-end))]
                (when (not= value nil)
                  (tset result num value)
                  (set num (+ num 1))))
              (do
                (tset result num (sub text expr-begin expr-end))
                (set num (+ num 1))))

            (set prefix (+ expr-end 1))
            (set at (+ expr-end 1)))))
      ;; No more matches, finish
      (do
        (tset result num (sub text prefix))
        (set at (+ len 1)))))

  (table.concat result))


{: expandvar} 
