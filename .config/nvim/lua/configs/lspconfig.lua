local nvlsp = require "nvchad.configs.lspconfig"

-- NvChad's on_attach adds buffer-local <leader>wa/wr/wl, <leader>D and
-- <leader>ra. Once a server attaches those shadow the Doom SPC w window map
-- (SPC w l is "window right"). The LSP actions live under SPC c in
-- mappings.lua, so keep only gd/gD here. defaults() reads this at attach time.
nvlsp.on_attach = function(_, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc }
  end
  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts "Go to declaration")
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts "Go to definition")
end

-- Capabilities, diagnostics, lua_ls.
nvlsp.defaults()

-- Server configs come from nvim-lspconfig's lsp/*.lua; binaries from Mason
-- (NvChad puts mason/bin on PATH). Install them all with :MasonInstallAll.
--
-- Neovim quietly skips a server whose cmd is a list naming a missing binary.
-- html, cssls and ts_ls build their cmd in a function, which skips that
-- check: a missing binary is an error and a "Press ENTER" prompt on every
-- matching file. So those are enabled only once installed (chadrc.lua lists
-- them for :MasonInstallAll, since it only sees enabled servers).
local servers = {
  "pyright",
  "ruff",
  "bashls", -- sh/bash only; zsh gets treesitter highlighting
}
for _, s in ipairs {
  { "html", "vscode-html-language-server" },
  { "cssls", "vscode-css-language-server" },
  { "ts_ls", "typescript-language-server" },
} do
  if vim.fn.executable(s[2]) == 1 then
    table.insert(servers, s[1])
  end
end
vim.lsp.enable(servers)

-- pyright only speaks UTF-16; make ruff match so both share one encoding.
vim.lsp.config("ruff", {
  capabilities = vim.tbl_deep_extend("force", nvlsp.capabilities, {
    general = { positionEncodings = { "utf-16" } },
  }),
})

-- pyright owns hover in Python; ruff is there for lint, fixes and imports.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end
  end,
})

-- read :h vim.lsp.config for changing options of lsp servers
