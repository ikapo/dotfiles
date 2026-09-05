-- Doom Emacs keymap for NvChad, ported from .config/zed/keymap.json.
--
-- Doom command names are noted next to each binding, the same way the Zed
-- keymap does it, so the two stay diffable by eye.
--
-- Leader is SPC (set in init.lua). Group prefixes: b f p s g c w o t h q.

require "nvchad.mappings"

local map = vim.keymap.set

-- NvChad binds several <leader><key> actions that sit exactly where a Doom
-- group prefix goes -- <leader>b, <leader>h and <leader>w* would each shadow a
-- whole menu. Drop those before defining ours. pcall keeps this quiet if
-- NvChad reshuffles its defaults.
local function unmap(mode, lhs)
  pcall(vim.keymap.del, mode, lhs)
end

for _, lhs in ipairs {
  "<leader>b", -- shadows the b (buffer) group
  "<leader>h", -- shadows the h (help) group
  "<leader>v",
  "<leader>e",
  "<leader>x", -- SPC x is Doom's scratch buffer
  "<leader>/", -- SPC / is Doom's search-project
  "<leader>n",
  "<leader>rn",
  "<leader>ch",
  "<leader>ds",
  "<leader>fw",
  "<leader>fb",
  "<leader>fh",
  "<leader>fo",
  "<leader>fz",
  "<leader>ma",
  "<leader>cm",
  "<leader>gt",
  "<leader>pt",
  "<leader>th",
  "<leader>wK",
  "<leader>wk",
} do
  unmap("n", lhs)
end
unmap("n", "<leader>fm")
unmap("x", "<leader>fm")

-- ── which-key group labels ──────────────────────────────────────────
local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add {
    { "<leader>b", group = "buffer" },
    { "<leader>f", group = "file" },
    { "<leader>p", group = "project" },
    { "<leader>s", group = "search" },
    { "<leader>g", group = "git" },
    { "<leader>c", group = "code" },
    { "<leader>w", group = "window" },
    { "<leader>o", group = "open" },
    { "<leader>t", group = "toggle" },
    { "<leader>h", group = "help" },
    { "<leader>q", group = "quit" },
  }
end

-- ── Top level ───────────────────────────────────────────────────────
map("n", ";", ":", { desc = "CMD enter command mode" })

map("n", "<leader><leader>", "<cmd>Telescope find_files<CR>", { desc = "find file in project" })
map("n", "<leader>.", "<cmd>Telescope find_files<CR>", { desc = "find file" })
map("n", "<leader>,", "<cmd>Telescope buffers<CR>", { desc = "switch workspace buffer" })
-- A literal "<" in an lhs has to be written <lt>, or it is parsed as the start
-- of a key notation and the mapping silently never registers.
map("n", "<leader><lt>", "<cmd>Telescope buffers show_all_buffers=true<CR>", { desc = "switch buffer (all)" })
map("n", "<leader>:", ":", { desc = "M-x (command mode)" })
map("n", "<leader>/", "<cmd>Telescope live_grep<CR>", { desc = "search project" })
map("n", "<leader>`", "<C-^>", { desc = "switch to last buffer" })
map("n", "<leader>'", "<cmd>Telescope resume<CR>", { desc = "resume last search" })
map("n", "<leader>x", "<cmd>enew<CR>", { desc = "open scratch buffer" })

map("v", "<leader>/", "<cmd>Telescope live_grep<CR>", { desc = "search project" })

-- ── b — buffers ─────────────────────────────────────────────────────
local function tabufline(fn, ...)
  local args = { ... }
  return function()
    require("nvchad.tabufline")[fn](unpack(args))
  end
end

map("n", "<leader>bb", "<cmd>Telescope buffers<CR>", { desc = "switch workspace buffer" })
map("n", "<leader>bB", "<cmd>Telescope buffers show_all_buffers=true<CR>", { desc = "switch buffer" })
map("n", "<leader>bd", tabufline "close_buffer", { desc = "kill buffer" })
map("n", "<leader>bk", tabufline "close_buffer", { desc = "kill buffer" })
map("n", "<leader>bK", tabufline("closeAllBufs", true), { desc = "kill all buffers" })
map("n", "<leader>bO", tabufline("closeAllBufs", false), { desc = "kill other buffers" })
map("n", "<leader>bn", tabufline "next", { desc = "next buffer" })
map("n", "<leader>b]", tabufline "next", { desc = "next buffer" })
map("n", "<leader>bp", tabufline "prev", { desc = "previous buffer" })
map("n", "<leader>b[", tabufline "prev", { desc = "previous buffer" })
map("n", "<leader>bN", "<cmd>enew<CR>", { desc = "new empty buffer" })
map("n", "<leader>bl", "<C-^>", { desc = "switch to last buffer" })
map("n", "<leader>bs", "<cmd>w<CR>", { desc = "save buffer" })
map("n", "<leader>bS", "<cmd>wa<CR>", { desc = "save all buffers" })
map("n", "<leader>br", "<cmd>Telescope oldfiles<CR>", { desc = "reopen recent buffer" })

-- ── f — files ───────────────────────────────────────────────────────
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "find file" })
map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", { desc = "recent files" })
map(
  "n",
  "<leader>fa",
  "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
  { desc = "find file (incl. hidden)" }
)
map("n", "<leader>fs", "<cmd>w<CR>", { desc = "save file" })
map("n", "<leader>fS", ":saveas ", { desc = "save file as..." })
map("n", "<leader>fn", "<cmd>enew<CR>", { desc = "create new file" })
map("n", "<leader>fc", "<cmd>enew<CR>", { desc = "create new file" })

map("n", "<leader>fp", function()
  require("telescope.builtin").find_files { cwd = vim.fn.stdpath "config" }
end, { desc = "open private config" })

map("n", "<leader>fP", function()
  vim.cmd.edit(vim.fn.stdpath "config" .. "/lua/mappings.lua")
end, { desc = "open keymap file" })

map("n", "<leader>fy", function()
  local path = vim.fn.expand "%:p"
  vim.fn.setreg("+", path)
  vim.notify("Yanked: " .. path)
end, { desc = "yank file path" })

map("n", "<leader>fY", function()
  local path = vim.fn.fnamemodify(vim.fn.expand "%:p", ":.")
  vim.fn.setreg("+", path)
  vim.notify("Yanked: " .. path)
end, { desc = "yank path from project" })

map("n", "<leader>fd", "<cmd>NvimTreeFindFile<CR>", { desc = "dired (reveal in tree)" })

map("n", "<leader>fE", function()
  vim.fn.jobstart { "open", "-R", vim.fn.expand "%:p" }
end, { desc = "reveal in Finder" })

-- ── p — project ─────────────────────────────────────────────────────
map("n", "<leader>pp", "<cmd>Telescope projects<CR>", { desc = "switch project" })
map("n", "<leader>pf", "<cmd>Telescope find_files<CR>", { desc = "find file in project" })
map("n", "<leader>ps", "<cmd>wa<CR>", { desc = "save project files" })
map("n", "<leader>pc", "<cmd>make<CR>", { desc = "compile in project" })

-- ── s — search ──────────────────────────────────────────────────────
map("n", "<leader>ss", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "search buffer" })
map("n", "<leader>sp", "<cmd>Telescope live_grep<CR>", { desc = "search project" })
map("n", "<leader>si", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "jump to symbol (imenu)" })
map("n", "<leader>sI", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", { desc = "jump to symbol in workspace" })
map("n", "<leader>sm", "<cmd>Telescope marks<CR>", { desc = "jump to bookmark" })
map("n", "<leader>st", "<cmd>TodoTelescope<CR>", { desc = "search TODOs" })

-- ── g — git ─────────────────────────────────────────────────────────
local function gitsigns(fn, ...)
  local args = { ... }
  return function()
    local ok, gs = pcall(require, "gitsigns")
    if ok then
      gs[fn](unpack(args))
    end
  end
end

-- Runs a git subcommand in a NvChad terminal split, the way SPC g f/p/P
-- shell out in Doom rather than opening a UI.
local function git_cmd(args)
  return function()
    require("nvchad.term").new { pos = "sp", cmd = "git " .. args .. " ; echo; echo '-- done --'" }
  end
end

map("n", "<leader>gg", "<cmd>LazyGit<CR>", { desc = "magit status (lazygit)" })
map("n", "<leader>gG", "<cmd>Telescope git_status<CR>", { desc = "git status picker" })
map("n", "<leader>gs", gitsigns "stage_buffer", { desc = "git stage file" })
map("n", "<leader>gU", gitsigns "reset_buffer_index", { desc = "git unstage file" })
map("n", "<leader>gb", "<cmd>Telescope git_branches<CR>", { desc = "switch branch" })
map("n", "<leader>gB", gitsigns("blame_line", { full = true }), { desc = "git blame" })
map("n", "<leader>gd", gitsigns "diffthis", { desc = "git diff" })
map("n", "<leader>gc", "<cmd>LazyGit<CR>", { desc = "git commit" })
map("n", "<leader>gr", gitsigns "reset_hunk", { desc = "git revert hunk" })
map("n", "<leader>gL", "<cmd>Telescope git_commits<CR>", { desc = "git log" })
map("n", "<leader>gf", git_cmd "fetch --all --prune", { desc = "git fetch" })
map("n", "<leader>gp", git_cmd "pull --ff-only", { desc = "git pull" })
map("n", "<leader>gP", git_cmd "push", { desc = "git push" })

-- hunk-level, Doom's SPC g h map
map("n", "<leader>ghp", gitsigns "preview_hunk", { desc = "preview hunk" })
map("n", "<leader>ghs", gitsigns "stage_hunk", { desc = "stage hunk" })
map("n", "<leader>ghr", gitsigns "reset_hunk", { desc = "reset hunk" })

map("v", "<leader>gr", function()
  require("gitsigns").reset_hunk { vim.fn.line ".", vim.fn.line "v" }
end, { desc = "revert selected hunk" })

-- ── c — code ────────────────────────────────────────────────────────
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "execute code action" })
map("v", "<leader>ca", vim.lsp.buf.code_action, { desc = "code action on selection" })
map("n", "<leader>cd", vim.lsp.buf.definition, { desc = "jump to definition" })
map("n", "<leader>cD", vim.lsp.buf.references, { desc = "jump to references" })
map("n", "<leader>ci", vim.lsp.buf.implementation, { desc = "find implementations" })
map("n", "<leader>ct", vim.lsp.buf.type_definition, { desc = "find type definition" })
map("n", "<leader>ck", vim.lsp.buf.hover, { desc = "show documentation" })
map("n", "<leader>cs", vim.lsp.buf.signature_help, { desc = "signature help" })

map("n", "<leader>cr", function()
  require "nvchad.lsp.renamer"()
end, { desc = "LSP rename" })

map({ "n", "x" }, "<leader>cf", function()
  require("conform").format { lsp_fallback = true }
end, { desc = "format buffer" })

map("n", "<leader>co", function()
  vim.lsp.buf.code_action {
    context = { only = { "source.organizeImports" }, diagnostics = {} },
    apply = true,
  }
end, { desc = "organize imports" })

map("n", "<leader>cj", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", { desc = "jump to symbol in workspace" })
map("n", "<leader>cx", "<cmd>Trouble diagnostics toggle<CR>", { desc = "list errors" })
map("n", "<leader>cX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", { desc = "list buffer errors" })
map("n", "<leader>ce", vim.diagnostic.open_float, { desc = "floating diagnostic" })
map("n", "<leader>cc", "<cmd>make<CR>", { desc = "compile" })
map("n", "<leader>cC", "<cmd>make!<CR>", { desc = "recompile" })

-- ── w — windows (evil-window-map) ───────────────────────────────────
map("n", "<leader>wv", "<C-w>v", { desc = "vsplit" })
map("n", "<leader>ws", "<C-w>s", { desc = "split" })
map("n", "<leader>wh", "<C-w>h", { desc = "window left" })
map("n", "<leader>wj", "<C-w>j", { desc = "window down" })
map("n", "<leader>wk", "<C-w>k", { desc = "window up" })
map("n", "<leader>wl", "<C-w>l", { desc = "window right" })
map("n", "<leader>wH", "<C-w>H", { desc = "move window left" })
map("n", "<leader>wJ", "<C-w>J", { desc = "move window down" })
map("n", "<leader>wK", "<C-w>K", { desc = "move window up" })
map("n", "<leader>wL", "<C-w>L", { desc = "move window right" })
map("n", "<leader>ww", "<C-w>w", { desc = "next window" })
map("n", "<leader>wW", "<C-w>W", { desc = "previous window" })
map("n", "<leader>wc", "<C-w>c", { desc = "close window" })
map("n", "<leader>wd", "<C-w>c", { desc = "delete window" })
map("n", "<leader>wq", "<C-w>c", { desc = "quit window" })
map("n", "<leader>wo", "<C-w>o", { desc = "delete other windows" })
map("n", "<leader>wx", "<C-w>x", { desc = "swap windows" })
map("n", "<leader>w=", "<C-w>=", { desc = "balance windows" })
map("n", "<leader>w>", "<C-w>5>", { desc = "widen window" })
map("n", "<leader>w<lt>", "<C-w>5<", { desc = "narrow window" })
map("n", "<leader>w+", "<C-w>5+", { desc = "heighten window" })
map("n", "<leader>w-", "<C-w>5-", { desc = "shorten window" })

-- Doom's SPC w m toggles a zoomed window; vim has no native toggle, so
-- track the state per tab and equalize on the way back out.
map("n", "<leader>wm", function()
  if vim.t.zoomed then
    vim.cmd "wincmd ="
    vim.t.zoomed = false
  else
    vim.cmd "wincmd _ | wincmd |"
    vim.t.zoomed = true
  end
end, { desc = "maximize window (toggle)" })

-- ── o — open ────────────────────────────────────────────────────────
map("n", "<leader>op", "<cmd>NvimTreeToggle<CR>", { desc = "project sidebar" })
map("n", "<leader>oP", "<cmd>NvimTreeFindFile<CR>", { desc = "find file in sidebar" })

map("n", "<leader>ot", function()
  require("nvchad.term").toggle { pos = "float", id = "floatTerm" }
end, { desc = "toggle terminal popup" })

map("n", "<leader>oT", function()
  require("nvchad.term").new { pos = "sp" }
end, { desc = "open terminal here" })

map("n", "<leader>og", "<cmd>LazyGit<CR>", { desc = "open lazygit" })
map("n", "<leader>om", "<cmd>MarkdownPreviewToggle<CR>", { desc = "markdown preview" })

-- Zed's agent panel has no in-editor equivalent here; the CLIs are the agent,
-- so open them in a float. Mirrors the cl/co aliases in .config/aliasrc.
map("n", "<leader>oa", function()
  require("nvchad.term").toggle { pos = "float", id = "claudeTerm", cmd = "claude" }
end, { desc = "AI agent (claude)" })

map("n", "<leader>oA", function()
  require("nvchad.term").toggle { pos = "float", id = "codexTerm", cmd = "codex" }
end, { desc = "AI agent (codex)" })

-- ── t — toggles ─────────────────────────────────────────────────────
map("n", "<leader>tl", "<cmd>set nu!<CR>", { desc = "line numbers" })
map("n", "<leader>tr", "<cmd>set rnu!<CR>", { desc = "relative line numbers" })
map("n", "<leader>tw", "<cmd>set wrap!<CR>", { desc = "soft line wrapping" })
map("n", "<leader>ts", "<cmd>set spell!<CR>", { desc = "spell check" })

map("n", "<leader>ti", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = 0 }, { bufnr = 0 })
end, { desc = "inlay hints" })

map("n", "<leader>tt", function()
  require("nvchad.themes").open()
end, { desc = "load theme" })

-- ── h — help ────────────────────────────────────────────────────────
map("n", "<leader>ht", function()
  require("nvchad.themes").open()
end, { desc = "load theme" })

map("n", "<leader>hh", "<cmd>Telescope help_tags<CR>", { desc = "help topics" })
map("n", "<leader>hc", "<cmd>NvCheatsheet<CR>", { desc = "cheatsheet" })
map("n", "<leader>hm", "<cmd>Telescope man_pages<CR>", { desc = "man pages" })
map("n", "<leader>hk", "<cmd>Telescope keymaps<CR>", { desc = "describe key" })
map("n", "<leader>hK", "<cmd>WhichKey<CR>", { desc = "all keymaps" })

-- ── q — quit ────────────────────────────────────────────────────────
map("n", "<leader>qq", "<cmd>qa<CR>", { desc = "quit nvim" })
map("n", "<leader>qQ", "<cmd>qa!<CR>", { desc = "quit nvim without saving" })
map("n", "<leader>qf", "<cmd>q<CR>", { desc = "delete frame" })

-- ── Doom bracket motions ────────────────────────────────────────────
map("n", "]e", function()
  vim.diagnostic.jump { count = 1, severity = vim.diagnostic.severity.ERROR }
end, { desc = "next error" })

map("n", "[e", function()
  vim.diagnostic.jump { count = -1, severity = vim.diagnostic.severity.ERROR }
end, { desc = "previous error" })

map("n", "]b", tabufline "next", { desc = "next buffer" })
map("n", "[b", tabufline "prev", { desc = "previous buffer" })

map("n", "]t", function()
  require("todo-comments").jump_next()
end, { desc = "next todo comment" })

map("n", "[t", function()
  require("todo-comments").jump_prev()
end, { desc = "previous todo comment" })

-- ── Misc Doom habits ────────────────────────────────────────────────
-- Keep the selection when indenting, the way evil does.
map("v", "<", "<gv", { desc = "indent left" })
map("v", ">", ">gv", { desc = "indent right" })

-- Don't clobber the yank register when pasting over a selection.
map("x", "p", 'p:let @+=@0<CR>:let @"=@0<CR>', { desc = "paste without yanking", silent = true })
