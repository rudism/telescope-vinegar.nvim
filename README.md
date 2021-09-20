# telescope-vinegar.nvim

A modified version of [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)'s built-in file browser with behavior inspired by [vim-vinegar](https://github.com/tpope/vim-vinegar) and [vim-filebeagle](https://github.com/jeetsukumaran/vim-filebeagle).

## Usage

File browser opens in the current buffer's directory in normal mode by default.

- `-` goes up a level to the parent directory
- `/` enters insert mode to search files
- `+` prompts for a new file name to create
- `h` toggles whether hidden files are displayed or not

## Installation

Install with packer (or similar equivalent package manager):

```lua
use 'rudism/telescope-vinegar.nvim'
```

Bind this to a key (I recommend `-`) and execute it to open the file browser in the current file's directory:

```lua
require('telescope').extensions.vinegar.file_browser()
```

## Example Config

The following config maps `-` to the file browser, disables `netrw`, and automatically opens the file browser when you launch nvim with a directory as the file argument (uses [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)).

```lua
-- add keybinding
vim.api.nvim_set_keymap('n', '-',
  '<cmd>lua require("telescope").extensions.vinegar.file_browser()<cr>',
  {noremap = true})

-- disable netrw
vim.g['loaded_netrw'] = 1

-- create function to open file browser when opening a directory
_G.browse_if_dir = function()
  if require('plenary.path'):new(vim.fn.expand('%:p')):is_dir() then
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'buflisted', false)
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')
    require('telescope').extensions.vinegar.file_browser()
  end
end

-- autocommand to run the above function when launching
vim.api.nvim_command('au VimEnter * call v:lua.browse_if_dir()')
```
