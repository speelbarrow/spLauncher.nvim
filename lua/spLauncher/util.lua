local M = {}

--- Override the action map for the buffer when a language server attaches with a valid `root_dir`
---@param lsp string The language server name
---@param config spLauncher.Config | fun(string): spLauncher.Config The override configuration for 'workspace' mode to be merged in
---@param bufnr? integer The buffer whose action map should be modified, defaults to `vim.api.nvim_get_current_buf()`
function M.workspace(lsp, config, bufnr)
  vim.api.nvim_create_autocmd("LspAttach", {
    buffer = bufnr or vim.api.nvim_get_current_buf(),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)

      if client and client.name == lsp and client.config.root_dir ~= nil and client.config.root_dir ~= "" then
        vim.b[args.buf].spLauncherActionMap = vim.tbl_deep_extend("force", vim.b[args.buf].spLauncherActionMap or {},
                                                                  type(config) == "function" and
                                                                  config(client.config.root_dir) or config)
      end
    end,
  })
end

return M
