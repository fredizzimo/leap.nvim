(local api vim.api)


(fn cursor-before-eol? []
  (not= (vim.fn.search "\\_." "Wn") (vim.fn.line ".")))


(fn cursor-before-eof? []
  (and (= (vim.fn.line ".") (vim.fn.line "$"))
       (= (vim.fn.virtcol ".") (- (vim.fn.virtcol "$") 1))))


(fn push-cursor! [dir]
  "Push cursor 1 character to the left or right, possibly beyond EOL."
  (vim.fn.search "\\_." (case dir :fwd "W" :bwd "bW")))


(fn add-offset! [col offset]
  ; TODO: Handle multibyte   
  (math.max 0 (- (+ col (or offset 0)) 1)))


(fn push-beyond-eof! []
  (local saved vim.o.virtualedit)
  (set vim.o.virtualedit :onemore)
  ; Note: No need to undo this afterwards, the cursor will be moved to
  ; the end of the operated area anyway.
  (vim.cmd "norm! l")
  (api.nvim_create_autocmd
    [:CursorMoved :WinLeave :BufLeave :InsertEnter :CmdlineEnter :CmdwinEnter]
    {:callback #(set vim.o.virtualedit saved) :once true}))


(fn simulate-inclusive-op! [mode]
  "When applied after an exclusive motion (like setting the cursor via
the API), make the motion appear to behave as an inclusive one."
  (case (vim.fn.matchstr mode "^no\\zs.")  ; get forcing modifier
    ; In the normal case (no modifier), we should push the cursor
    ; forward. (The EOF edge case requires some hackery though.)
    "" -2
    ; We also want the `v` modifier to behave in the native way, that
    ; is, to toggle between inclusive/exclusive if applied to a charwise
    ; motion (:h o_v). As `v` will change our (technically) exclusive
    ; motion to inclusive, we should push the cursor back to undo that.
    :v -1
    ; Blockwise (<c-v>) itself makes the motion inclusive, do nothing in
    ; that case.
    _ -1))


(fn force-matchparen-refresh []
  ; HACK: :DoMatchParen turns matchparen on simply by triggering
  ; CursorMoved events (see matchparen.vim). We can do the same, which
  ; is cleaner for us than calling :DoMatchParen directly, since that
  ; would wrap this in a `windo`, and might visit another buffer,
  ; breaking our visual selection (and thus also dot-repeat,
  ; apparently). (See :h visual-start, and lightspeed#38.)
  ; Programming against the API would be more robust of course, but in
  ; the unlikely case that the implementation details would change, this
  ; still cannot do any damage on our side if called with pcall (the
  ; feature just ceases to work then).
  (pcall api.nvim_exec_autocmds "CursorMoved" {:group "matchparen"})
  ; If vim-matchup is installed, it can similarly be forced to refresh
  ; by triggering a CursorMoved event. (The same caveats apply.)
  (pcall api.nvim_exec_autocmds "CursorMoved" {:group "matchup_matchparen"}))


(fn jump-to! [pos {: winid : add-to-jumplist? : mode
                   : offset : backward? : inclusive-op?}]
  (local op-mode? (mode:match :o))
  ; Note: <C-o> will ignore this if the line has not changed (neovim#9874).
  (when add-to-jumplist? (vim.cmd "norm! m`"))
  (when (not= winid (vim.fn.win_getid))
    (api.nvim_set_current_win winid))
  ; TODO: Handle till (both linewise and normal)
  (when (= mode :no) (vim.cmd "norm! v"))  
  (let [(row col) (unpack pos)]
    (vim.api.nvim_win_set_cursor winid [row (add-offset! col offset)]))
        ; Since Vim interprets our jump as an exclusive motion (:h exclusive),
        ; we need custom tweaks to behave as an inclusive one. (This is only
        ; relevant in the forward direction, as inclusiveness applies to the
        ; end of the selection.)
        ;(if (and op-mode? inclusive-op? (not backward?)) (simulate-inclusive-op! mode) 0)))]))
  (when (not op-mode?) (force-matchparen-refresh)))


{: jump-to!}
