---@type table
local M = {}
---@type table
M.default_config = {
  ---@type string
  prompt = "command> ",
  ---@type string you can open with: "float", "message", "terminal".
  open_with = "terminal",
  ---@type string file where commands are saved.
  commands_file = vim.fn.stdpath("data") .. "/command.nvim/commands.lua",
  ---@type table optios to customize the window when `open_with` is set to float.
  float = {
    ---@type string
    close_key = "<ESC>",
    ---@type string Window border (see ':h nvim_open_win')
    border = "none",
    ---@type number Num from `0 - 1` for measurements
    height = 0.8,
    ---@type number
    width = 0.8,
    ---@type number
    x = 0.5,
    ---@type number
    y = 0.5,
    ---@type string Highlight group for floating window/border (see ':h winhl')
    border_hl = "FloatBorder",
    ---@type string
    float_hl = "Normal",
    ---@type number Transparency (see ':h winblend')
    blend = 0,
  },
}
---@type function
local open
---@type table
M.commands = {}

--- saves a key value pair table of the directories and their respective commands
function M.save_commands()
  os.execute("mkdir -p " .. vim.fs.dirname(M.config.commands_file))
  local file, err = io.open(M.config.commands_file, "w")

  if file then
    file:write(
      "---@type table\n"
        .. [[require("command").commands = ]]
        .. vim.inspect(M.commands)
    )
    file:close()
  else
    error("Error opening file: " .. err)
  end
end

--- executes a command according to your current working directory on the `commands` table
function M.command()
  local cwd = vim.fn.getcwd()
  pcall(dofile, M.config.commands_file)

  ---@param command string|nil
  local function prompt(command)
    vim.ui.input(
      { prompt = M.config.prompt, default = command },
      function(input)
        command = input
        if command ~= nil then
          open(command)

          if not vim.tbl_contains(M.commands[cwd], command) then
            table.insert(M.commands[cwd], 1, command)
            M.save_commands()
          end
        end
      end
    )
  end

  if M.commands[cwd] == nil then
    M.commands[cwd] = {}
  end

  if #M.commands[cwd] == 0 then
    prompt()
  elseif #M.commands[cwd] == 1 then
    prompt(M.commands[cwd][1])
  else
    vim.ui.select(
      M.commands[cwd],
      { prompt = "Select a command" },
      function(choice)
        prompt(choice)
      end
    )
  end
end

---@param config table|nil
function M.setup(config)
  if config == nil then
    M.config = M.default_config
  else
    vim.validate({ config = { config, "table", true } })
    M.config = vim.tbl_deep_extend("force", M.default_config, config or {})
  end

  if M.config.open_with == "float" then
    open = function(cmd)
      require("command.utils").floating(cmd)
    end
  elseif M.config.open_with == "message" then
    open = function(cmd)
      vim.cmd(":!" .. cmd)
    end
  else
    open = function(cmd)
      vim.cmd(":terminal " .. cmd)
    end
  end
end

return M
