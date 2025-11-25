return {
  {
    'saghen/blink.cmp',
    dependencies = { 'rafamadriz/friendly-snippets' },
    version = '1.*',
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = { preset = 'default' },
      appearance = {
        nerd_font_variant = 'mono'
      },
      completion = { documentation = { auto_show = false } },
    },
    opts_extend = { "sources.default" }
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
          library = {
            -- Load luvit types when the `vim.uv` word is found
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
      },
    },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()
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
      })

      vim.lsp.config("ruff", {
        cmd = { "ruff", "server" },
        root_markers = { "pyproject.toml" },
        init_options = {
          settings = {
            logLevel = "debug",
          }
        }
      })
      vim.lsp.config("pyright", { cmd = { "uvx", "--from", "pyright", "pyright-langserver", "--stdio" } })
      vim.lsp.config("mojo", { cmd = { "pixi", "run", "mojo-lsp-server" } })
      vim.lsp.enable({ "lua_ls", "pyright", "ruff", "mojo" })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then return end
          -- Format on save
          if client.supports_method("textDocument/formatting", 0) then
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = args.buf,
              callback = function()
                vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
              end,
            })
          end
        end
      })
      -- Format Mojo files on save using the CLI
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
  }
}
