-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

local M = {
  last_testname = '',
  last_testpath = '',
}

local tests_query = [[
(function_declaration
  name: (identifier) @testname
  parameters: (parameter_list
    . (parameter_declaration
      type: (pointer_type) @type) .)
  (#match? @type "*testing.(T|M)")
  (#match? @testname "^Test.+$")) @parent
]]

local subtests_query = [[
(call_expression
  function: (selector_expression
    operand: (identifier)
    field: (field_identifier) @run)
  arguments: (argument_list
    (interpreted_string_literal) @testname
    (func_literal))
  (#eq? @run "Run")) @parent
]]

local function format_subtest(testcase, test_tree)
  local parent
  if testcase.parent then
    for _, curr in pairs(test_tree) do
      if curr.name == testcase.parent then
        parent = curr
        break
      end
    end
    return string.format('%s/%s', format_subtest(parent, test_tree), testcase.name)
  else
    return testcase.name
  end
end

local function get_closest_above_cursor(test_tree)
  local result
  for _, curr in pairs(test_tree) do
    if not result then
      result = curr
    else
      local node_row1, _, _, _ = curr.node:range()
      local result_row1, _, _, _ = result.node:range()
      if node_row1 > result_row1 then
        result = curr
      end
    end
  end
  if result then
    return format_subtest(result, test_tree)
  end
  return nil
end

local function is_parent(dest, source)
  if not (dest and source) then
    return false
  end
  if dest == source then
    return false
  end

  local current = source
  while current ~= nil do
    if current == dest then
      return true
    end

    current = current:parent()
  end

  return false
end

local function get_closest_test()
  local stop_row = vim.api.nvim_win_get_cursor(0)[1]
  local ft = vim.api.nvim_buf_get_option(0, 'filetype')
  assert(ft == 'go', 'can only find test in go files, not ' .. ft)
  local parser = vim.treesitter.get_parser(0)
  local root = (parser:parse()[1]):root()

  local test_tree = {}

  local test_query = vim.treesitter.query.parse(ft, tests_query)
  assert(test_query, 'could not parse test query')
  for _, match, _ in test_query:iter_matches(root, 0, 0, stop_row) do
    local test_match = {}
    for id, node in pairs(match) do
      local capture = test_query.captures[id]
      if capture == 'testname' then
        local name = vim.treesitter.get_node_text(node, 0)
        test_match.name = name
      end
      if capture == 'parent' then
        test_match.node = node
      end
    end
    table.insert(test_tree, test_match)
  end

  local subtest_query = vim.treesitter.query.parse(ft, subtests_query)
  assert(subtest_query, 'could not parse test query')
  for _, match, _ in subtest_query:iter_matches(root, 0, 0, stop_row) do
    local test_match = {}
    for id, node in pairs(match) do
      local capture = subtest_query.captures[id]
      if capture == 'testname' then
        local name = vim.treesitter.get_node_text(node, 0)
        test_match.name = string.gsub(string.gsub(name, ' ', '_'), '"', '')
      end
      if capture == 'parent' then
        test_match.node = node
      end
    end
    table.insert(test_tree, test_match)
  end

  table.sort(test_tree, function(a, b)
    return is_parent(a.node, b.node)
  end)

  for _, parent in ipairs(test_tree) do
    for _, child in ipairs(test_tree) do
      if is_parent(parent.node, child.node) then
        child.parent = parent.name
      end
    end
  end

  return get_closest_above_cursor(test_tree)
end

local function get_package_name()
  local test_dir = vim.fn.fnamemodify(vim.fn.expand '%:.:h', ':r')
  return './' .. test_dir
end

M.closest_test = function()
  local package_name = get_package_name()
  local test_case = get_closest_test()
  local test_scope
  if test_case then
    test_scope = 'testcase'
  else
    test_scope = 'package'
  end
  return {
    package = package_name,
    name = test_case,
    scope = test_scope,
  }
end

M.get_root_dir = function()
  local id, client = next(vim.lsp.buf_get_clients())
  if id == nil then
    error { error_msg = 'lsp client not attached' }
  end
  if not client.config.root_dir then
    error { error_msg = 'lsp root_dir not defined' }
  end
  return client.config.root_dir
end

local function get_test()
  -- args = { '-test.run', '^TestSubscribeV3CustomerExists$' },
  local test = M.closest_test()
  return coroutine.create(function(dap_run_co)
    local args = { '-test.run', '^' .. test.name .. '$' }
    vim.ui.input({ prompt = 'closest_test ' .. test.name }, function(input)
      coroutine.resume(dap_run_co, args)
    end)
  end)
end

local function debug_test(testname, testpath, build_flags)
  local dap = require 'dap'
  dap.run {
    type = 'go',
    name = testname,
    request = 'launch',
    mode = 'test',
    program = testpath,
    args = { '-test.run', '^' .. testname .. '$' },
    buildFlags = build_flags,
  }
end

function M.debug_test()
  local test = M.closest_test()

  if test.name == '' then
    vim.notify 'no test found'
    return false
  end

  M.last_testname = test.name
  M.last_testpath = test.package

  local msg = string.format("starting debug session '%s : %s'...", test.package, test.name)
  vim.notify(msg)
  debug_test(test.name, test.package, M.test_buildflags)

  return true
end

local function filtered_pick_process()
  local opts = {}
  vim.ui.input({ prompt = 'Search by process name (lua pattern), or hit enter to select from the process list: ' }, function(input)
    opts['filter'] = input or ''
  end)
  return require('dap.utils').pick_process(opts)
end

return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  lazy = false,
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_setup = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {
        delve = function(config)
          config = {
            adapters = {
              executable = {
                command = 'b5env',
                args = { '-d', './config/environments/lcl', '-c', 'dlv dap -l 127.0.0.1:${port}' },
                -- args = { "dap", "-l", "127.0.0.1:${port}" },
                -- command = "/Users/johnbauer/.local/share/nvim/mason/bin/dlv",
              },
              port = '${port}',
              type = 'server',
            },
            configurations = {
              {
                type = 'delve',
                name = 'Attach',
                mode = 'local',
                request = 'attach',
                processId = filtered_pick_process,
              },
              {
                name = 'LOL Delve: Debug',
                program = '${file}',
                request = 'launch',
                type = 'delve',
              },
              {
                mode = 'test',
                name = 'Delve: Debug test',
                program = '${file}',
                request = 'launch',
                type = 'delve',
              },
              {
                mode = 'test',
                name = 'Delve: Debug test (go.mod)',
                program = './${relativeFileDirname}',
                request = 'launch',
                type = 'delve',
              },
              {
                type = 'delve',
                name = 'Closest Function',
                request = 'launch',
                mode = 'test',
                program = './${relativeFileDirname}',
                args = get_test,
                -- args = { '-test.run', '^TestSubscribeV3CustomerExists$' },
              },
            },
            filetypes = { 'go' },
            name = 'delve',
          }
          require('mason-nvim-dap').default_setup(config) -- don't forget this!
        end,
      },

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
      },
    }
    -- Basic debugging keymaps, feel free to change to your liking!
    vim.keymap.set('n', '<leader>i', require('dapui').eval, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<F1>', dap.step_into, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<F2>', dap.step_over, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<F3>', dap.step_out, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    vim.keymap.set('n', '<leader>B', function()
      dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
    end, { desc = 'Debug: Set Breakpoint' })

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Install golang specific config
    --   require('dap-go').setup {
    --     delve = {
    --       path = 'b5env',
    --       args = { '-d', './config/environments/lcl', '-c', 'dlv dap -l 127.0.0.1:${port}' },
    --     },
    --   }
  end,
}
