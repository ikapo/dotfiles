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
    -- mkdp#util#install fails under lazy.nvim (E117: the plugin is not on
    -- the runtimepath yet when the build runs) and only ships x86_64 binaries
    -- anyway. Installing the node app instead works on macOS and ARM Linux;
    -- --no-package-lock keeps the plugin's git checkout clean for updates.
    build = "cd app && npm install --no-package-lock --no-fund --no-audit",
    init = function()
      vim.g.mkdp_auto_close = 0
      vim.g.mkdp_theme = "dark"
    end,
  },

  -- SPC t p — Zed's editor::ToggleEditPrediction. Inline ghost-text
  -- suggestions, toggled on demand. Reads the same credentials Zed uses,
  -- at ~/.config/github-copilot, so no separate sign-in.
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = {
        enabled = true,
        -- Off by default, the way Zed's prediction toggle starts quiet;
        -- SPC t p turns it on for the session.
        auto_trigger = false,
        keymap = {
          accept = "<M-l>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      -- The separate panel duplicates what SPC t p already gives us.
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        gitcommit = true,
        ["*"] = true,
      },
    },
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

  -- NvChad v2.5 follows nvim-treesitter's `main` branch (Neovim 0.12+). Its
  -- parsers are compiled locally by the tree-sitter CLI (0.26.1+) and a C
  -- compiler, and nothing installs them on its own: NvChad's build step
  -- (`:TSUpdate | TSInstallAll`) runs before TSInstallAll is defined on a
  -- fresh install. So: plain :TSUpdate on build, and missing parsers are
  -- installed the first time a file is opened. Once they exist this is one
  -- directory listing.
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function(_, opts)
      local ts = require "nvim-treesitter"
      ts.setup(opts)

      local have = {}
      for _, lang in ipairs(ts.get_installed "parsers") do
        have[lang] = true
      end
      local missing = vim.tbl_filter(function(lang)
        return not have[lang]
      end, opts.ensure_installed or {})
      if #missing == 0 then
        return
      end

      local has_cc = vim.fn.executable(vim.env.CC or "cc") == 1 or vim.fn.executable "gcc" == 1
      if vim.fn.executable "tree-sitter" == 0 or not has_cc then
        vim.schedule(function()
          vim.notify(
            ("treesitter: %d parsers missing; needs tree-sitter-cli 0.26.1+ and a C compiler"):format(#missing),
            vim.log.levels.WARN
          )
        end)
        return
      end

      ts.install(missing, { summary = true }):await(function()
        vim.schedule(function()
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) and not vim.treesitter.highlighter.active[buf] then
              pcall(vim.treesitter.start, buf)
            end
          end
        end)
      end)
    end,
    opts = {
      ensure_installed = {
        "vim",
        "vimdoc",
        "lua",
        "luadoc",
        "bash",
        "zsh",
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
