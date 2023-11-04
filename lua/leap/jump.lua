local api = vim.api
local function cursor_before_eol_3f()
  return (vim.fn.search("\\_.", "Wn") ~= vim.fn.line("."))
end
local function cursor_before_eof_3f()
  return ((vim.fn.line(".") == vim.fn.line("$")) and (vim.fn.virtcol(".") == (vim.fn.virtcol("$") - 1)))
end
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
  return math.max(0, ((col + (offset or 0)) - 1))
end
local function push_beyond_eof_21()
  local saved = vim.o.virtualedit
  vim.o.virtualedit = "onemore"
  vim.cmd("norm! l")
  local function _2_()
    vim.o.virtualedit = saved
    return nil
  end
  return api.nvim_create_autocmd({"CursorMoved", "WinLeave", "BufLeave", "InsertEnter", "CmdlineEnter", "CmdwinEnter"}, {callback = _2_, once = true})
end
local function simulate_inclusive_op_21(mode)
  local _3_ = vim.fn.matchstr(mode, "^no\\zs.")
  if (_3_ == "") then
    return -2
  elseif (_3_ == "v") then
    return -1
  elseif true then
    local _ = _3_
    return -1
  else
    return nil
  end
end
local function force_matchparen_refresh()
  pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchparen"})
  return pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchup_matchparen"})
end
local function jump_to_21(pos, _5_)
  local _arg_6_ = _5_
  local winid = _arg_6_["winid"]
  local add_to_jumplist_3f = _arg_6_["add-to-jumplist?"]
  local mode = _arg_6_["mode"]
  local offset = _arg_6_["offset"]
  local backward_3f = _arg_6_["backward?"]
  local inclusive_op_3f = _arg_6_["inclusive-op?"]
  local op_mode_3f = mode:match("o")
  if add_to_jumplist_3f then
    vim.cmd("norm! m`")
  else
  end
  if (winid ~= vim.fn.win_getid()) then
    api.nvim_set_current_win(winid)
  else
  end
  if (mode == "no") then
    vim.cmd("norm! v")
  else
  end
  do
    local row, col = unpack(pos)
    vim.api.nvim_win_set_cursor(winid, {row, add_offset_21(col, offset)})
  end
  if not op_mode_3f then
    return force_matchparen_refresh()
  else
    return nil
  end
end
return {["jump-to!"] = jump_to_21}
