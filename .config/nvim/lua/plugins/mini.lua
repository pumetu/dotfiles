return {
  {
    'echasnovski/mini.statusline',
    version = false,
    config = function()
      require("mini.statusline").setup()
    end
  },
  {
    "echasnovski/mini.pairs",
    version = false,
    config = function()
      require("mini.pairs").setup()
    end
  },
}
