(local api vim.api)


(fn push-cursor! [dir]
  "Push cursor 1 character to the left or right, possibly beyond EOL."
  (vim.fn.search "\\_." (case dir :fwd "W" :bwd "bW")))


(fn add-offset! [col offset]
  (math.max 0 (+ col (or offset 0))))


(fn fixup-exclusion! [exclusive-charwise-op]
  (when exclusive-charwise-op (vim.cmd "norm! h"))
  ; We need to take into account that the selection option can be set
  ; to exclusive or the operator pending might select too little.
  ; Note this does not deal with "selection=old", since using that should
  ; be very uncommon and it can't properly deal with targets at the end of the line.
  (when (= vim.o.selection "exclusive")
    (vim.cmd "norm! l")))

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
                   : offset : inclusive-op?}]
  (local op-mode? (mode:match :o))
  ; Note: <C-o> will ignore this if the line has not changed (neovim#9874).
  (when add-to-jumplist? (vim.cmd "norm! m`"))
  (when (not= winid (vim.fn.win_getid))
    (api.nvim_set_current_win winid))
  (local charwise-op (or (= mode "no") (= mode "nov")))
  (local (start-row start-col) (unpack (vim.fn.getcursorcharpos) 2))
  (local first-non-blank (= (. (vim.fn.searchpos "\\S" "bWn" start-row) 1) 0))
  (local exclusive-charwise-op
    (and charwise-op (= (= mode "nov") inclusive-op?)))
  ; Treat nil offsets as 0
  (local offset (or offset 0))

  ; Get the actual position in characters, so we don't need to deal with byte positions
  (local (row col) (unpack (vim.fn.getcharpos pos) 2))
  (local offset-column (add-offset! col offset))
  (local backwards (or (< row start-row) (and (= row start-row) (< offset-column start-col))))
  ; The inclusive/exclusive mode always applies to end of the selection, so it needs to be done
  ; before moving to the target if the motion is backwards.
  (when (and backwards charwise-op) (fixup-exclusion! exclusive-charwise-op))

  ; Always force inclusive operations internally, since there's no way for us to force
  ; exclusive if the user already has forced it.
  ; Vim handles exclusive motions in a special way (:h exclusive)
  ; and there's no way to undo the automatic linewise change (:h exclusive-linewise),
  ; but we can simulate the other way around, so inclusive is strictly better for us.
  (when charwise-op (vim.cmd "norm! v"))

  ; Move to the target position without any offsets first
  (vim.fn.cursor pos)

  ; Go to the end of the previous line if the offset is negative and we are on the first column
  ; This works in all modes, and also simulates exclusive motions (:h exclusive)
  (if (and (= col 1) (< offset 0))
    (push-cursor! :bwd)
    (vim.fn.setcursorcharpos row offset-column))

  (when (and (not backwards) charwise-op) (fixup-exclusion! exclusive-charwise-op))

  ; When the motion is exclusive charwise and starts before or at the first non-blank
  ; and ends on the first column, the motion should be linewise (:h exclusive-linewise)
  (when (and exclusive-charwise-op first-non-blank (= col 1))
    (vim.cmd "norm! V"))

  (when (not op-mode?) (force-matchparen-refresh)))


{: jump-to!}
