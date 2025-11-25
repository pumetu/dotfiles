------- Options ------
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

vim.o.clipboard = 'unnamedplus'
vim.g.clipboard = require('vim.ui.clipboard.osc52').tool

vim.o.number = true         -- line numbers
vim.o.relativenumber = true -- relative line numbers
vim.o.mouse = 'a'           -- enable mouse mode

-- Editing/Tab
vim.o.tabstop = 2           -- <tab> inserts 4 spaces
vim.o.shiftwidth = 2        -- And an indent level is 4 spaces wide.
vim.o.softtabstop = 2       -- <BS> over an autoindent deletes both spaces.
vim.o.expandtab = true      -- Use spaces, not tabs, for autoindent/tab key.
vim.o.shiftround = true     -- rounds indent to a multiple of shiftwidth
vim.o.virtualedit = 'block' -- In C-v mode, allow moving past EOL.

-- Browsing/navigating
vim.o.scrolloff = 3         -- Keep 3 context lines above and below the cursor
vim.o.foldmethod = 'indent' -- allow us to fold on indents
vim.o.foldlevel = 99        -- but don't fold anything right away!
vim.o.autoread = true       -- autoread changed files (mainly for mojo formatting)

-- LSP
vim.o.winborder = "rounded"
vim.o.completeopt = "menuone,noselect,popup"

----- Auto Commands -----
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python", "mojo" },
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})

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

----- Keymaps -----
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Line diagnostics" })

----- Plugins -----
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    {
      "catppuccin/nvim",
      config = function()
        require("catppuccin").setup({ auto_integrations = true })
        vim.cmd.colorscheme("catppuccin-mocha")
      end
    },
    -- LSP
    {
      'saghen/blink.cmp',
      dependencies = { 'rafamadriz/friendly-snippets' },
      version = '1.*',
      opts = {
        keymap = { preset = 'default' },
        appearance = {
          nerd_font_variant = 'mono'
        },
      },
      opts_extend = { "sources.default" }
    },
    {
      "neovim/nvim-lspconfig",
      config = function()
        local capabilities = require("blink.cmp").get_lsp_capabilities()
        -- Lua
        vim.lsp.config["lua_ls"] = {
          settings = {
            Lua = {
              workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
              },
              diagnostics = { disable = { 'missing-fields' } },
            }
          }
        }
        vim.lsp.enable("lua_ls")
        -- Python
        vim.lsp.config("pyright", {
          settings = {
            pyright = {
              disableOrganizeImports = true,
            },
            python = {
              analysis = {
                ignore = { "*" },
              },
            },
          },
          cmd = { "uvx", "--from", "pyright", "pyright-languageserver", "--stdio" },
        })
        vim.lsp.enable("pyright")

        vim.lsp.config("ruff", {
          cmd = { "ruff", "server" },
          root_markers = { "pyproject.toml" },
          init_options = {
            settings = {
              logLevel = "debug",
            }
          }
        })
        vim.lsp.enable("ruff")
        -- Mojo
        vim.lsp.config("mojo", { cmd = { "pixi", "run", "mojo-lsp-server" } })
        vim.lsp.enable("mojo")
        -- Format on save
        vim.api.nvim_create_autocmd('LspAttach', {
          group = vim.api.nvim_create_augroup('my.lsp', {}),
          callback = function(args)
            local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

            -- Auto-format ("lint") on save.
            -- Usually not needed if server supports "textDocument/willSaveWaitUntil".
            if not client:supports_method('textDocument/willSaveWaitUntil')
                and client:supports_method('textDocument/formatting') then
              vim.api.nvim_create_autocmd('BufWritePre', {
                group = vim.api.nvim_create_augroup('my.lsp', { clear = false }),
                buffer = args.buf,
                callback = function()
                  vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 })
                end,
              })
            end
          end,
        })
        -- Format Mojo files
        vim.api.nvim_create_autocmd("BufWritePost", {
          pattern = "*.mojo",
          callback = function()
            -- Format the file on disk
            vim.fn.jobstart({ "pixi", "run", "mojo", "format", "--line-length", "120", vim.api.nvim_buf_get_name(0) }, {
              on_exit = function()
                -- Reload buffer after formatting
                if vim.api.nvim_buf_is_loaded(0) then
                  vim.cmd("checktime") -- reload if file changed externally
                end
              end,
            })
          end,
        })
        vim.diagnostic.config({
          virtual_text = false,     -- ⛔ no inline text
          signs = true,             -- ✅ gutter signs
          underline = true,         -- ✅ underline the problem
          update_in_insert = false, -- don't distract while typing
          severity_sort = true,     -- show most severe first
          float = {
            border = "rounded",
            source = "if_many",
          },
        })
      end,
    },
    {
      "nvim-treesitter/nvim-treesitter",
      branch = "master",
      lazy = false,
      build = ":TSUpdate",
      config = function()
        require 'nvim-treesitter.configs'.setup({
          ensure_installed = { "lua", "python", "markdown" },
          auto_install = false,
          highlight = {
            enable = true,
            disable = function(lang, buf)
              local max_filesize = 100 * 1024 -- 100 KB
              local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
              if ok and stats and stats.size > max_filesize then
                return true
              end
            end,
            additional_vim_regex_highlighting = false,
          },
        })
      end
    },
    {
      'nvim-telescope/telescope.nvim',
      tag = '0.1.8',
      dependencies = {
        'nvim-lua/plenary.nvim',
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      },
      config = function()
        vim.keymap.set("n", "<space>ff", function()
          require("telescope.builtin").find_files({ follow = true })
        end)
        vim.keymap.set("n", "<space>fn", function() -- edit neovim from anywhere
          require("telescope.builtin").find_files({
            cwd = vim.fn.stdpath("config"), follow = true
          })
        end)
      end
    },
    -- Mini
    {
      'nvim-mini/mini.statusline',
      version = false,
      config = function()
        require("mini.statusline").setup()
      end
    },
  },

  checker = { enabled = true },
})
