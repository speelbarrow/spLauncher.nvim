---@meta _

---@class spLauncher.ActionMap See `:help splauncher-actions`
---@field base? string
--- If set to a non-empty string value, it will be prepended with a space to any string handler and then use the result
--- as the command to run in the terminal. This also comes with the caveat that `"base"` is not a valid action name.
---@field [string] spLauncher.Handler | { handler: spLauncher.Handler, config: spLauncher.Config }
--- See `:help spLauncher-handlers`

---@alias spLauncher.Handler # See `:help spLauncher-handlers`
---| spLauncher.Handler.String
---| spLauncher.Handler.Function

---@alias spLauncher.Handler.String # See `:help spLauncher-handlers-string`
---| string
---| true
---| fun(): string
---| fun(): boolean

---@alias spLauncher.Handler.Function fun(): nil # See `:help spLauncher-handlers-function`

---@class spLauncher.Config See `:help spLauncher-config`
---@field notify? boolean Default: `false`
--- When `true`, outputs the actual string that is executed by spLauncher before doing so. Uses `vim.notify` to display
--- the string.
---@field silent? boolean Default: `false`
--- When `true`, executes commands in the background without displaying a terminal window.
---@field expand? boolean Default: `true`
--- When `true`, processes string commands through the |expand| function. More specifically, will match any `'%'`
--- character and all non-whitespace characters immediately after it, and will run those through |expand|.
---@field window? spLauncher.Config.Window See `:help spLauncher-config-window`
---@field keymap? spLauncher.Config.Keymap See `:help spLauncher-config-keymap`

---@class spLauncher.Config.Window See `:help spLauncher-config-window`
---@field focus? boolean | "insert" Default: `true`
--- When `true`, moves the focus to the terminal window upon opening. When set to `"insert"`, moves the focus to the
--- terminal window AND enters 'Insert' mode upon opening. Set to `false` to disable both of these behaviors.
---@field persist? boolean Default: `true`
--- spLauncher uses the Neovim terminal to execute command-line actions. By default, the window will stay open after the
--- program has exited until input is attempted. To override this (i.e. close the window immediately after the program
--- exits), set `persist` to `false`.
---@field position? "below" | "above" | "left" | "right" Default: `"below"`
--- Defines which area of the screen should hold the new window when spLauncher opens a terminal. `"above"` and
--- `"below"` will result in horizontal splits, and `"left"` and `"right"` result in vertical splits. See
--- `nvim_open_win` for more information.

---@class spLauncher.Config.Keymap See `:help spLauncher-config-keymap`
---@field merge boolean Default: `true`
--- Whether or not to merge any provided keymaps with the defaults. When false, the default keymaps are discarded
--- entirely in favor of the provided configuration.
---@field actions? table<string, string | string[]> Default: `{}`
--- A table of action names and their corresponding keys. NOTE: This has no effect when set as configuration for a
--- specific handler (see `:help spLauncher-handlers-config`).
---@field sigint? string | string[] Default: `"<C-c>"`
--- Key(s) to send `SIGINT` to the program running in a terminal window opened by spLauncher. If the program has already
--- exited, this will close the terminal window.
---@field close? string | string[] Default: `{"<Esc>", "q"}`
--- Key(s) to close the terminal window opened by spLauncher (if the program is still running, this does nothing).
---@field force_close? string | string[] Default: `"<C-q>"`
--- Key(s) to close the terminal window, killing the process if it is still running.
