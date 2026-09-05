-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "doomchad",
  theme_toggle = { "doomchad", "one_light" },

  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
  },
}

M.ui = {
  -- Doom shows the buffer bar immediately, not after the 2nd buffer.
  tabufline = {
    lazyload = false,
  },
}

M.nvdash = {
  load_on_startup = true,

  header = {
    "                                                     ",
    "     ██████╗  ██████╗  ██████╗ ███╗   ███╗           ",
    "     ██╔══██╗██╔═══██╗██╔═══██╗████╗ ████║           ",
    "     ██║  ██║██║   ██║██║   ██║██╔████╔██║           ",
    "     ██║  ██║██║   ██║██║   ██║██║╚██╔╝██║           ",
    "     ██████╔╝╚██████╔╝╚██████╔╝██║ ╚═╝ ██║           ",
    "     ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝     ╚═╝           ",
    "                                                     ",
    "         D O O M   E M A C S ,   I N   V I M         ",
    "                                                     ",
  },

  -- Buttons advertise the Doom bindings, not NvChad's.
  buttons = {
    { txt = "  Find File", keys = "SPC f f", cmd = "Telescope find_files" },
    { txt = "  Recent Files", keys = "SPC f r", cmd = "Telescope oldfiles" },
    { txt = "󰈭  Search Project", keys = "SPC /", cmd = "Telescope live_grep" },
    { txt = "  Switch Project", keys = "SPC p p", cmd = "Telescope projects" },
    { txt = "  Git", keys = "SPC g g", cmd = "LazyGit" },
    { txt = "󱥚  Themes", keys = "SPC h t", cmd = ":lua require('nvchad.themes').open()" },
    { txt = "  Mappings", keys = "SPC h c", cmd = "NvCheatsheet" },

    { txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },

    {
      txt = function()
        local stats = require("lazy").stats()
        local ms = math.floor(stats.startuptime) .. " ms"
        return "  Loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms
      end,
      hl = "NvDashFooter",
      no_gap = true,
      content = "fit",
    },

    { txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },
  },
}

M.lsp = { signature = true }

return M
