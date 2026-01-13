-- bootstrap lazy.nvim, LazyVim and your plugins

require("config.lazy")
require("lazy").setup(plugins, {
  defaults = { lazy = true },
  install = { missing = true },
  checker = { enabled = true },
  change_detection = { enabled = false },
})
