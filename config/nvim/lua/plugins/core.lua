return {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      sort_by = "case_sensitive",
      view = { width = 34 },
      renderer = { group_empty = true },
      filters = { dotfiles = false },
      actions = { open_file = { quit_on_open = false } },
    },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "File Tree" },
      { "<leader>o", "<cmd>NvimTreeFocus<cr>", desc = "Focus File Tree" },
    },
  },

  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signcolumn = true,
      current_line_blame = true,
      current_line_blame_opts = { delay = 300 },
    },
  },

  {
    "tpope/vim-fugitive",
    keys = {
      { "<leader>gg", "<cmd>Git<cr>", desc = "Git Status" },
      { "<leader>gb", "<cmd>Git blame<cr>", desc = "Git Blame" },
    },
  },

  {
    "nvim-telescope/telescope.nvim",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.lua_ls = {}
      opts.servers.nil_ls = {}
      opts.servers.ts_ls = {}
      opts.servers.pyright = {}
    end,
  },

  {
    "supermaven-inc/supermaven-nvim",
    event = "InsertEnter",
    opts = {
      keymaps = {
        accept_suggestion = "<C-l>",
        clear_suggestion = "<C-]>",
        accept_word = "<C-j>",
      },
    },
  },
  {
    "AckslD/nvim-neoclip.lua",
    dependencies = { "kkharji/sqlite.lua", "nvim-telescope/telescope.nvim" },
    config = function()
      require("neoclip").setup()
      require("telescope").load_extension("neoclip")
    end,
    keys = {
      { "<leader>fy", "<cmd>Telescope neoclip<cr>", desc = "Clipboard History" },
    },
  },
}
