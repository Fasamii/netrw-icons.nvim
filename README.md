# netrw-icons.nvim

An extension plugin for Neovim’s built-in `netrw` file explorer that adds:

- File and directory icons
- LSP diagnostics indicators

## Features

- No replacement of `netrw` — pure extension
- File and directory icons inside `netrw`
- Supports multiple icon providers:
  - `nvim-web-devicons`
  - `mini.icons`
- LSP diagnostics integration

## Requirements

- Neovim ≥ 0.9
- One of the following (optional):
  - [`nvim-web-devicons`](https://github.com/nvim-tree/nvim-web-devicons)
  - [`mini.icons`](https://github.com/echasnovski/mini.nvim)
- Neovim built-in LSP (optional, for diagnostics)

## Installation

Using `lazy.nvim`:

```lua
{
  "yourname/netrw-plus.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons", -- or "echasnovski/mini.nvim",       
  },
  config = function()
    require("netrw-plus").setup({
        prefer = "devicons"
        file = true,
        dir = true,
        lsp = {
            info = false,
            hint = false,
            warn = true,
            error = true,
        }
    })
  end,
}
