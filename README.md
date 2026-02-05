# netrw-icons.nvim

An extension plugin for Neovim’s built-in `netrw` file explorer that adds:

- File and directory icons
- LSP diagnostics indicators

## Features

- No replacement of `netrw` - pure extension
- File and directory icons inside `netrw`
- Supports multiple icon providers:
  - `nvim-web-devicons`
  - `mini.icons`
- LSP diagnostics integration

## Requirements

- Neovim ≥ 0.9
- One of the following:
  - [`nvim-web-devicons`](https://github.com/nvim-tree/nvim-web-devicons)
  - [`mini.icons`](https://github.com/echasnovski/mini.nvim)
- Neovim built-in LSP (optional, for diagnostics)

## Installation

Using `lazy.nvim`:

```lua
{
  "yourname/netrw-plus.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons", -- or "nvim-mini/mini.icons",       
  },
  config = function()
    require("netrw-plus").setup({
        prefer = "devicons" -- if set to nil will detect automatically

        file = true, -- should display file icons
	    file_default = true, -- should use default icon for file

        dir = " ", -- directory icon set to false if none

        lsp = { -- which lsp diagnostics to display set lsp = false for none
            info = false,
            hint = false,
            warn = true,
            error = true,
        }
    })
  end,
}
