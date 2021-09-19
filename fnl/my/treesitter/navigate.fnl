(local util (require "nvim-treesitter.ts_utils"))

(local fun (require "my.fun"))


(local node-at-cursor
  util.get_node_at_cursor)


(fn iter-children-next [state idx]
  (when (< idx (. state 3))
    (values (+ idx 1) ((. state 1) (. state 2) idx))))


(fn iter-children [node]
  [iter-children-iterator [node.child node (node:child_count)] 0])


(fn range-compare [ar ac br bc]
  (or (< ar br)
      (and (= ar br) (<= ac bc))))


(fn range-match [asr asc aer aec bsr bsc ber bec]
  (and
    (= asr bsr)
    (= asc bsc)
    (= aer ber)
    (= aec bec)))


(fn prev-sibling [node]
  (when (not= nil node)
    (local n (node:prev_sibling))
    (if (not= nil n) n
      (prev-sibling (node:parent)))))


(fn next-sibling [node]
  (when (not= nil node)
    (local n (node:next_sibling))
    (if (not= nil n) n
      (next-sibling (node:parent)))))


(fn deep [node row col]
  (var (sr sc er ec) (node:range))
  (set ec (math.max 0 (- ec 1)))
  (if
    (and (<= sr row er) (<= sc col ec))
    (node:descendant_for_range row col row col)
    (or (< row sr) (< col sc))
    (node:descendant_for_range sr sc sr sc)
    (or (< er row) (< ec col))
    (node:descendant_for_range er ec er ec)))


(fn siblings-around [node]
  (when (not= nil node)
    (local parent (node:parent node))
    (when (not= nil parent)
      (local child-count (parent:child_count))
      (let [first (parent:child 0)
            last (parent:child (- child-count 1))]
        (match node
          first (values (prev-sibling parent) last)
          last (values first (next-sibling parent))
          _ (values (prev-sibling node) (next-sibling node)))))))


(fn sibling-forward [node]
  (when (not= nil node)
    (local parent (node:parent node))
    (when (not= nil parent)
      (local last (parent:child (- (parent:child_count) 1)))
      (if (= node last)
        (next-sibling parent)
        (next-sibling node)))))


(fn sibling-backward [node]
  (when (not= nil node)
    (local parent (node:parent node))
    (when (not= nil parent)
      (local first (parent:child 0))
      (if (= node first)
        (prev-sibling parent)
        (prev-sibling node)))))


(fn children-around-cursor [node row col start end]
  (if (< 1 (- end start))
    (let [point (math.floor (+ start (/ (- end start) 2)))
          child (node:child point)
          (child-row-begin
            child-col-begin
            child-row-end
            child-col-end) (child:range)]
      (if (range-compare child-row-end child-col-end row col)
        (children-around-cursor node row col point end)
        (children-around-cursor node row col start point)))
    (values (node:child start) (node:child end))))


(fn nodes-around-cursor [node row col]
  (children-around-cursor node row col 0 (node:child_count)))


(fn nodes-around-cursor-linear [node row col]
  (when (not= nil node)
    (local num-children (node:child_count))
    (var prev-node nil)
    (var next-node nil)
    (for [i 0 (math.max 0 (- num-children 1)) :until (not= nil next-node)]
      (local child (node:child i))
      (local (child-row-begin child-col-begin child-row-end child-col-end)
             (child:range))
      (if (range-compare child-row-end child-col-end row col)
          (set prev-node child)
          (set next-node child)))
    (values prev-node next-node)))


(fn get-cursor []
  (local cursor (vim.api.nvim_win_get_cursor 0))
  (values (- (. cursor 1) 1) (. cursor 2)))


(fn ensure-cursor [row col]
  (if (or (= nil row) (= nil col))
    (do
      (local (nrow ncol) (get-cursor))
      (values (or row nrow) (or col ncol)))
    (values row col)))



(fn pick-last-idx [iter state idx]
  (var oidx idx)
  (var nidx (iter state oidx))
  (while (not= nil nidx)
    (set oidx nidx)
    (set nidx (iter state nidx)))
  oidx)


(fn parent-iterator [state idx]
  (idx:parent))


(fn iter-parents [node]
  (if (not= nil node)
    (values parent-iterator nil node)
    (values fun.raw.empty nil nil)))


(fn raise-while [func node]
  (or (pick-last-idx
        (fun.raw.take-while-kv
           func (iter-parents node)))
      node))


(fn make-node-range-matcher [sr sc er ec]
  (fn [node]
    (local (psr psc per pec) (node:range))
    (range-match sr sc er ec psr psc per pec)))


(fn make-node-start-matcher [row col]
  (fn [node]
    (local (nrow ncol) (node:start))
    (and (= row nrow) (= col ncol))))


(fn make-node-end-matcher [row col]
  (fn [node]
    (local (nrow ncol) (node:end_))
    (and (= row nrow) (= col (- ncol 1)))))


(fn raise-node-combined [node row col]
  (var n (raise-while (make-node-range-matcher (node:range)) node))
  (set n (raise-while (make-node-start-matcher row col) n))
  (set n (raise-while (make-node-end-matcher row col) n))
  (set n (raise-while (make-node-range-matcher (n:range)) n))
  n)


(fn node-at-cursor [row col]
  (local (row col) (ensure-cursor row col))
  (local root (util.get_root_for_position row col))
  (when root (root:descendant_for_range row col row col)))


(fn node-at-cursor-backward [row col]
  (local (row col) (ensure-cursor row col))
  (local root (util.get_root_for_position row col))
  (when root
    (local node (root:descendant_for_range row col row col))
    (if (< 0 (node:child_count))
      (let [(back forth) (nodes-around-cursor node row col)
            (r c) (back:end_)]
        (back:descendant_for_range rc rc rc))
      node)))


(fn node-at-cursor-forward [row col]
  (local (row col) (ensure-cursor row col))
  (local root (util.get_root_for_position row col))
  (when root
    (local node (root:descendant_for_range row col row col))
    (if (< 0 (node:child_count))
      (let [(back forth) (nodes-around-cursor node row col)
            (r c) (forth:start)]
        (forth:descendant_for_range r c r c))
      node)))


(fn get-current-node [row col]
  (local (row col) (ensure-cursor row col))
  (local node (node-at-cursor row col))
  (when node
    (if (< 0 (node:child_count))
      (let [(back forth) (nodes-around-cursor node row col)]
        (values back nil forth))
      (let [node (raise-node-combined node row col)
            (back forth) (siblings-around node)]
        (values back node forth)))))


(fn display-current-node []
  (local (p b n) (get-current-node))
  (values [p (when p (p:range))]
          [b (when b (b:range))]
          [n (when n (n:range))]))


(fn jump [row col]
  (vim.api.nvim_win_set_cursor 0 [row col]))


(fn jump-start [node]
  (local (row col) (node:start))
  (jump (+ row 1) col))


(fn jump-end [node]
  (local (row col) (node:end_))
  (jump (+ row 1) (math.max 0 (- col 1))))


(fn on-boundary? [node row col]
  (local (sr sc er ec) (node:range))
  (if (and (= sr row) (= sc col)) -1
      (and (= er row) (= (- ec 1) col)) 1
      0))


(fn forward-sexp []
  (local (row col) (get-cursor))
  (local (back base forth) (get-current-node row col))
  (if (and (not= nil base) (not= 1 (on-boundary? base row col)))
    (jump-end base)
    (when (not= nil forth) (jump-end forth))))


(fn backward-sexp []
  (local (row col) (get-cursor))
  (local (back base forth) (get-current-node row col))
  (if (and (not= nil base) (not= -1 (on-boundary? base row col)))
    (jump-start base)
    (when (not= nil back) (jump-start back))))


(fn up-list []
  (local (row col) (get-cursor))
  (-?> (node-at-cursor row col)
       (raise-node-combined row col)
       (: :parent)
       (jump-start)))


(fn down-list []
  (local (row col) (get-cursor))
  (-?> (node-at-cursor-forward row col)
       (next-sibling)
       (jump-start)))


(fn kill-sexp [])


(fn transpose-sexp [])


(fn mark-sexp [])


{: forward-sexp
 : backward-sexp
 : up-list
 : down-list
 : display-current-node
 : get-current-node}

;;; navigate.fnl ends here
