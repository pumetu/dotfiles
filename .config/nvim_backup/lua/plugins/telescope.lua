return {
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
}
