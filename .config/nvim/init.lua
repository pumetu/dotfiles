vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

require("config.lazy")

vim.o.clipboard = 'unnamedplus'

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
vim.o.autoread = false      -- Don't automatically re-read changed files, ask!

-- LSP
vim.o.winborder = "rounded"
vim.o.completeopt = "menuone,noselect,popup"

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
