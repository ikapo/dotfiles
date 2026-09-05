-- Plugins beyond NvChad's defaults, added only where a Doom binding in
-- lua/mappings.lua would otherwise have nothing to call.

return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- SPC g g — magit. lazygit is already on PATH via Homebrew.
  {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    init = function()
      vim.g.lazygit_floating_window_scaling_factor = 0.9
    end,
  },

  -- SPC c x — Doom's flycheck error list.
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {
      focus = true,
      warn_no_results = false,
      open_no_results = true,
    },
  },

  -- SPC p p — projectile. Detects project roots and feeds :Telescope projects.
  {
    "ahmedkhalf/project.nvim",
    event = "VeryLazy",
    config = function()
      require("project_nvim").setup {
        detection_methods = { "pattern", "lsp" },
        patterns = { ".git", "package.json", "go.mod", "Cargo.toml", "pyproject.toml", "Makefile", ".stow-local-ignore" },
        silent_chdir = true,
      }
      pcall(function()
        require("telescope").load_extension "projects"
      end)
    end,
  },

  -- SPC s t and ]t / [t — Doom's hl-todo + magit-todos.
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TodoTelescope", "TodoTrouble", "TodoQuickFix" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = true },
  },

  -- SPC o m — Zed's markdown::OpenPreview. Renders in the browser rather
  -- than a split; closest available equivalent.
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    ft = "markdown",
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    init = function()
      vim.g.mkdp_auto_close = 0
      vim.g.mkdp_theme = "dark"
    end,
  },

  -- Doom's evil-escape: jk leaves insert mode without eating a real "jk".
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    opts = {
      timeout = 300,
      mappings = {
        i = { j = { k = "<Esc>", j = "<Esc>" } },
        v = { j = { k = "<Esc>" } },
        t = { j = { k = "<C-\\><C-n>" } },
        c = { j = { k = "<Esc>" } },
      },
    },
  },

  -- Long paths are common in these repos; truncate from the left so the
  -- filename stays readable in every picker the Doom map opens.
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        path_display = { "truncate" },
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "vimdoc",
        "lua",
        "bash",
        "json",
        "yaml",
        "toml",
        "markdown",
        "markdown_inline",
        "go",
        "typescript",
        "tsx",
        "javascript",
        "python",
        "css",
        "html",
      },
    },
  },
}
