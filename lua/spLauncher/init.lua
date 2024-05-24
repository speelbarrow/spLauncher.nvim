local M = {}

---@param config? spLauncher.Config See `:help spLauncher-config`
function M.setup(config)
  --- Don't run `setup` twice
  if vim.g.spLauncherConfig ~= nil then
    error "refusing to run `spLauncher.setup` a second time"
  end

  vim.api.nvim_create_user_command("SpLaunch", function(opts)
                                     ---@type number?
                                     local bufnr = nil
                                     for index, action in ipairs(opts.fargs) do
                                       if index == 1 and type(action) == "number" and opts.nargs > 1 then
                                         bufnr = action
                                       elseif type(action) ~= "string" then
                                         vim.notify("invalid argument: '" .. action .. "'\n" ..
                                                    "usage: `:SpLaunch [bufnr] action1 [action2] [action3] ...",
                                                    vim.log.levels.ERROR)
                                       else
                                         M.spLaunch(action, bufnr)
                                       end
                                     end
                                   end, { nargs = "+" })

  vim.g.spLauncherConfig = vim.tbl_deep_extend("force", {
                                                 notify = false,
                                                 silent = false,
                                                 expand = true,
                                                 hide = false,
                                                 window = {
                                                   focus = true,
                                                   persist = true,
                                                   position = "below",
                                                   scroll = true,
                                                 },
                                                 keymap = (config ~= nil and config.keymap ~= nil and
                                                   config.keymap.merge == false) and nil or {
                                                   merge = true,
                                                   actions = {
                                                     run = "<M-s>r",
                                                     debug = "<M-s>d",
                                                     test = "<M-s>t",
                                                     build = "<M-s>b",
                                                     clean = "<M-s>c",
                                                   },
                                                   sigint = "<C-c>",
                                                   close = { "<Esc>", "q" },
                                                   force_close = "<C-q>",
                                                 },
                                               }, config or {})
  for action, key in pairs(vim.g.spLauncherConfig.keymap.actions) do
    vim.keymap.set("n", key, function()
      M.spLaunch(action)
    end)
  end

  -- Set up an empty action map for each buffer on enter
  vim.api.nvim_create_autocmd("BufNew", {
    callback = function()
      ---@type spLauncher.ActionMap
      vim.b.spLauncherActionMap = vim.b.spLauncherActionMap or {}
    end
  })
end

---@param action string See `:help spLauncher-actions`
---@param bufnr? number
--- By default, `vim.api.nvim_get_current_buf()` is used. This is used to choose which buffer's action map to get
--- handlers from.
---@param config? spLauncher.Config See `:help spLauncher-config`
function M.spLaunch(action, bufnr, config)
  -- Resolve buffer number
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Find the command in the appropriate action map
  ---@type spLauncher.Handler | { handler: spLauncher.Handler, config: spLauncher.Config } | nil
  local command = vim.b[bufnr].spLauncherActionMap[action]

  -- Make sure there is something there
  if command == nil then
    vim.notify("the '" .. action .. "' action is not defined for buffer " .. bufnr, vim.log.levels.ERROR)
  end

  -- Check what is there and deal with it appropriately
  if type(command) == "table" then
    config = vim.tbl_deep_extend("keep", command.config or {}, config or {})
    command = command.handler
  end
  if type(command) == "function" then
    command = command()
  end
  if type(command) == "boolean" and command then
    command = action
  end
  if type(command) == "string" then
    M.direct_spLaunch(
      (vim.b[bufnr].spLauncherActionMap.base and (vim.b[bufnr].spLauncherActionMap.base .. " ") or "") .. command, config)
  end
end

---@param command string
---@param config? spLauncher.Config See `:help spLauncher-config`
function M.direct_spLaunch(command, config)
  -- Resolve variables
  config = vim.tbl_deep_extend("keep", config or {}, vim.g.spLauncherConfig)
  if config.expand then
    command = command:gsub("%%%S*", vim.fn.expand)
  end

  -- Output command being run if `notify` is true
  if config.notify then
    vim.notify("spLauncher: spLaunching '" .. command .. "'", vim.log.levels.INFO)
  end

  -- Run command in terminal, when `silent` is true the window is not opened and the buffer is listed instead
  local term_buf = vim.api.nvim_create_buf((config.silent == true) or (config.hide ~= true), true)
  vim.api.nvim_buf_call(term_buf, function()
    vim.fn.termopen(command)
  end)

  -- Only open the window if `silent` is not set
  if not config.silent then
    vim.api.nvim_open_win(term_buf, not not config.window.focus, { split = config.window.position })

    -- Enter `insert` mode on focus
    if config.window.focus == "insert" then
      vim.schedule_wrap(vim.api.nvim_feedkeys)("i", "n", true)
    end
  end

  if config.window.persist == "force" then
    -- Configure auto-closing when `config.window.persist` is "force" (closes windows instead of buffers)
    vim.api.nvim_create_autocmd("TermClose", {
      buffer = term_buf,
      once = true,
      callback = vim.schedule_wrap(function()
        for _, win in ipairs(vim.fn.win_findbuf(term_buf)) do
          vim.api.nvim_win_close(win, false)
        end
        vim.api.nvim_buf_delete(term_buf, {})
      end),
    })
  elseif not config.window.persist or config.silent then
    -- Configure auto-closing when `config.window.persist` is false or if `silent` is on (i.e. the window is not open)
    vim.api.nvim_create_autocmd("TermClose", {
      buffer = term_buf,
      once = true,
      callback = function()
        vim.schedule_wrap(vim.api.nvim_buf_delete)(term_buf, {})
      end,
    })
  end

  -- Configure keymaps
  config.keymap.sigint = type(config.keymap.sigint) == "table" and config.keymap.sigint or { config.keymap.sigint }
  config.keymap.close = type(config.keymap.close) == "table" and config.keymap.close or { config.keymap.close }
  config.keymap.force_close = type(config.keymap.force_close) == "table" and config.keymap.force_close or
      { config.keymap.force_close }

  for _, key in ipairs(config.keymap.sigint --[[ @as string[] ]]) do
    vim.keymap.set("n", key, function()
                     vim.api.nvim_chan_send(vim.b[term_buf].terminal_job_id, "\003")
                   end, { buffer = term_buf })
  end

  for _, key in ipairs(config.keymap.force_close --[[ @as string[] ]]) do
    vim.keymap.set("n", key, function()
                     vim.api.nvim_chan_send(vim.b[term_buf].terminal_job_id, "\003")
                     vim.api.nvim_buf_delete(term_buf, { force = true })
                   end, { buffer = term_buf })
  end

  vim.api.nvim_create_autocmd("TermClose", {
    buffer = term_buf,
    once = true,
    callback = function(args)
      for _, key in ipairs(vim.iter {
        config.keymap.sigint,
        config.keymap.close,
        config.keymap.force_close,
      }:flatten():totable()) do
        vim.keymap.set({ "n", "i" }, key, function()
                         vim.api.nvim_buf_delete(args.buf, {})
                       end, { buffer = args.buf })
      end
    end
  })

  -- Move cursor to the bottom of the terminal window to automatically scroll the output (unless `scroll` is false)
  if config.window.scroll then
    vim.schedule_wrap(vim.api.nvim_buf_call)(term_buf, function() vim.cmd "normal! G" end)
  end
end

return M
