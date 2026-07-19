----------------
-- Options
----------------
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

vim.o.clipboard = 'unnamedplus'
vim.g.clipboard = require('vim.ui.clipboard.osc52').tool
vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}

vim.o.number = true         -- line numbers
vim.o.relativenumber = true -- relative line numbers
vim.o.mouse = 'a'           -- enable mouse mode

-- Editing/Tab
vim.o.tabstop = 4           -- <tab> inserts 4 spaces
vim.o.shiftwidth = 4        -- And an indent level is 4 spaces wide.
vim.o.softtabstop = 4       -- <BS> over an autoindent deletes both spaces.
vim.o.expandtab = true      -- Use spaces, not tabs, for autoindent/tab key.
vim.o.shiftround = true     -- rounds indent to a multiple of shiftwidth
vim.o.virtualedit = 'block' -- In C-v mode, allow moving past EOL.
vim.o.signcolumn = "yes"
vim.o.cmdheight = 0
vim.o.undodir = vim.fn.stdpath("data") .. "/undodir"
vim.o.undofile = true

-- Browsing/navigating
vim.o.scrolloff = 10         -- Keep 10 context lines above and below the cursor
vim.o.foldmethod = 'indent' -- allow us to fold on indents
vim.o.foldlevel = 99        -- but don't fold anything right away!

-- LSP
vim.o.winborder = "rounded"
vim.o.completeopt = "menuone,noselect,popup"

----------------
-- Auto Commands
----------------
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("my.lsp.format", { clear = true }),
  callback = function(ev)
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
    if client.name ~= "ruff" then
      return
    end

    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("my.lsp.format." .. ev.buf, { clear = true }),
      buffer = ev.buf,
      callback = function()
        -- Sort imports
        local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
        params.context = { only = { "source.organizeImports" }, diagnostics = {} }
        local resp = client:request_sync("textDocument/codeAction", params, 2000, ev.buf)
        for _, action in ipairs(resp and resp.result or {}) do
          if not action.edit and not action.command and client:supports_method("codeAction/resolve") then
            local resolved = client:request_sync("codeAction/resolve", action, 2000, ev.buf)
            if resolved and resolved.result then
              action = resolved.result
            end
          end
          if action.edit then
            vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
          end
          if action.command then
            local cmd = type(action.command) == "table" and action.command or action
            client:request_sync("workspace/executeCommand", cmd, 2000, ev.buf)
          end
        end

        -- Format
        vim.lsp.buf.format({ bufnr = ev.buf, id = client.id, timeout_ms = 2000 })
      end,
    })
  end,
})
----------------
-- Keymaps
----------------
-- LSP
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Line diagnostics" })

-- Editor
vim.keymap.set("x", "p", [["_dP]], { desc = "Paste over selection without losing yanked text" })
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

vim.keymap.set("v", "<", "<gv", { desc = "Unindent and keep selection" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent and keep selection" })

vim.keymap.set("n", "<C-c>", ":nohl<CR>", { desc = "Clear search highlighting", silent = true })

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "move down in buffer with cursor centered" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "move up in buffer with cursor centered" })

vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result cursor centered" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result cursor centered" })

vim.keymap.set("n", "<leader>re", "<cmd>restart<cr>", { desc = "Restart config :restart)" })

-- Undo Tree
vim.keymap.set("n", "<leader>u", function()
    vim.cmd.packadd("nvim.undotree")
    require("undotree").open()
end, { desc = "Toggle Builtin Undotree" })

----------------
-- Plugins
----------------
vim.pack.add({ 
    { src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
    "https://github.com/saghen/blink.lib",
    "https://github.com/saghen/blink.cmp",
    "https://github.com/neovim/nvim-lspconfig",
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", branch = "main", build = ":TSUpdate" },
    "https://github.com/FylerOrg/fyler.nvim",
    "https://github.com/nvim-mini/mini.icons",
    "https://github.com/nvim-mini/mini.pairs",
    "https://github.com/nvim-mini/mini.statusline",
    "https://github.com/nvim-mini/mini.pick"
})
-- Colorscheme
vim.cmd.colorscheme "catppuccin-nvim"

-- Mini
require("mini.statusline").setup({})
require("mini.pairs").setup({})
require("mini.pick").setup({
    mappings = {
        move_down = '<C-j>',
        move_up   = '<C-k>',
    }
})
vim.keymap.set('n', '<leader>ff', function() MiniPick.builtin.files() end,     { desc = 'Find files' })

-- Flyer
local fyler = require('fyler')
fyler.setup({
    integrations = {
        icon = "mini_icons",
    }
})
vim.keymap.set("n", "<leader>t", "<cmd>Fyler<cr>", { desc = "File explorer" })

-- Blink
local cmp = require('blink.cmp')
cmp.build():pwait()
cmp.setup()

-- TreeSitter
local treesitter = require("nvim-treesitter")
treesitter.setup({})
local ensure_installed = {
    "json",
    "lua",
    "markdown",
    "python",
    "bash",
}

local config = require("nvim-treesitter.config")

local already_installed = config.get_installed()
local parsers_to_install = {}

for _, parser in ipairs(ensure_installed) do
    if not vim.tbl_contains(already_installed, parser) then
        table.insert(parsers_to_install, parser)
    end
end

if #parsers_to_install > 0 then
    treesitter.install(parsers_to_install)
end

local group = vim.api.nvim_create_augroup("TreeSitterConfig", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(args)
        if vim.list_contains(config.get_installed(), vim.treesitter.language.get_lang(args.match)) then
            vim.treesitter.start(args.buf)
        end
    end,
})
-- Python
vim.lsp.config('ty', {
  settings = {
    ty = {
    }
  }
})
vim.lsp.enable('ty')

vim.lsp.config('ruff', {
  init_options = {
    settings = {
        configurationPreference = "filesystemFirst",
        lint = { extendSelect = { "I" } },
    }
  }
})

vim.lsp.enable('ruff')
