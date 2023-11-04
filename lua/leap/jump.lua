local api = vim.api
local function push_cursor_21(dir)
  local function _1_()
    if (dir == "fwd") then
      return "W"
    elseif (dir == "bwd") then
      return "bW"
    else
      return nil
    end
  end
  return vim.fn.search("\\_.", _1_())
end
local function add_offset_21(col, offset)
  return math.max(0, (col + (offset or 0)))
end
local function fixup_exclusion_21(exclusive_charwise_op)
  if exclusive_charwise_op then
    vim.cmd("norm! h")
  else
  end
  if (vim.o.selection == "exclusive") then
    return vim.cmd("norm! l")
  else
    return nil
  end
end
local function force_matchparen_refresh()
  pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchparen"})
  return pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchup_matchparen"})
end
local function jump_to_21(pos, _4_)
  local _arg_5_ = _4_
  local winid = _arg_5_["winid"]
  local add_to_jumplist_3f = _arg_5_["add-to-jumplist?"]
  local mode = _arg_5_["mode"]
  local offset = _arg_5_["offset"]
  local inclusive_op_3f = _arg_5_["inclusive-op?"]
  local op_mode_3f = mode:match("o")
  if add_to_jumplist_3f then
    vim.cmd("norm! m`")
  else
  end
  if (winid ~= vim.fn.win_getid()) then
    api.nvim_set_current_win(winid)
  else
  end
  local charwise_op = ((mode == "no") or (mode == "nov"))
  local start_row, start_col = unpack(vim.fn.getcursorcharpos(), 2)
  local first_non_blank = ((vim.fn.searchpos("\\S", "bWn", start_row))[1] == 0)
  local exclusive_charwise_op = (charwise_op and ((mode == "nov") == inclusive_op_3f))
  local offset0 = (offset or 0)
  local row, col = unpack(vim.fn.getcharpos(pos), 2)
  local offset_column = add_offset_21(col, offset0)
  local backwards = ((row < start_row) or ((row == start_row) and (offset_column < start_col)))
  if (backwards and charwise_op) then
    fixup_exclusion_21(exclusive_charwise_op)
  else
  end
  if charwise_op then
    vim.cmd("norm! v")
  else
  end
  vim.fn.cursor(pos)
  if ((col == 1) and (offset0 < 0)) then
    push_cursor_21("bwd")
  else
    vim.fn.setcursorcharpos(row, offset_column)
  end
  if (not backwards and charwise_op) then
    fixup_exclusion_21(exclusive_charwise_op)
  else
  end
  if (exclusive_charwise_op and first_non_blank and (col == 1)) then
    vim.cmd("norm! V")
  else
  end
  if not op_mode_3f then
    return force_matchparen_refresh()
  else
    return nil
  end
end
return {["jump-to!"] = jump_to_21}
